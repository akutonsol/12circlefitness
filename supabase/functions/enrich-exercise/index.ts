// AI exercise enrichment. Given an exercise slug, fetches its existing metadata,
// asks Claude to generate coaching content (instructions, leveled cues, common
// mistakes, breathing, per-goal AI tips), then re-seeds the full record via the
// seed_exercise RPC (idempotent by slug — metadata preserved, content added).
// Coach/admin only.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

const SYSTEM = `You are an expert strength and conditioning coach writing reference
content for an exercise library. Given an exercise and its metadata, produce
accurate, concise, technically-correct coaching content.

Respond with ONLY a JSON object — no prose, no markdown fences — in EXACTLY this shape:
{
  "description": "one-sentence summary of the exercise and its purpose",
  "step_by_step_instructions": [
    { "step": 1, "instruction": "imperative, specific cue (max ~15 words)" }
  ],
  "coaching_cues": {
    "beginner": ["short cue", "..."],
    "intermediate": ["short cue", "..."],
    "advanced": ["short cue", "..."]
  },
  "common_mistakes": [
    { "mistake": "what they do wrong", "problem": "why it matters", "fix": "the correction" }
  ],
  "alternative_exercises": [
    { "exercise": "Common Exercise Name", "reason": "why it's a good substitute" }
  ],
  "breathing": {
    "setup": "breathing cue before the rep",
    "concentric": "breathing during the working phase",
    "eccentric": "breathing during the lowering phase"
  },
  "ai_exercise_tips": {
    "fat_loss":    { "rep_range": "e.g. 12-15", "rest_period": "e.g. 30-45 seconds", "recommendation": "one sentence" },
    "muscle_gain": { "rep_range": "e.g. 8-12",  "rest_period": "e.g. 60-90 seconds", "recommendation": "one sentence" },
    "strength":    { "rep_range": "e.g. 3-6",   "rest_period": "e.g. 2-4 minutes",   "recommendation": "one sentence" },
    "endurance":   { "rep_range": "e.g. 15-20", "rest_period": "e.g. 30 seconds",    "recommendation": "one sentence" }
  }
}
Provide 4-7 instruction steps and 3-4 cues per level. Give 2-4 common mistakes
and 3-5 alternative_exercises (use widely-known exercise names so they can link
to the library). Prefer alternatives that train the same movement pattern.
For isometric/stretch/cardio/mobility exercises, adapt sensibly (e.g. hold/breath
cues instead of concentric/eccentric, time/distance instead of rep ranges). Never
invent equipment not implied by the metadata.`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);
    if (!ANTHROPIC_API_KEY) return json({ error: 'AI not configured' }, 500);

    // Coach/admin only.
    const { data: profile } = await userDb
      .from('user_profiles').select('role').eq('id', user.id).single();
    if (!profile || !['coach', 'admin'].includes(profile.role as string)) {
      return json({ error: 'Forbidden' }, 403);
    }

    const { slug } = await req.json() as { slug?: string };
    if (!slug) return json({ error: 'Provide an exercise slug' }, 400);

    // Existing metadata (so the AI has context and nothing is wiped on re-seed).
    const { data: ex } = await userDb
      .from('custom_exercises')
      .select('id, coach_id, name, slug, category, difficulty, movement_pattern, exercise_type, primary_muscles, secondary_muscles, equipment_required, body_region, goal_tags, supports_pr_tracking, supports_rpe_tracking, description')
      .eq('slug', slug).maybeSingle();
    if (!ex) return json({ error: 'Exercise not found' }, 404);

    const list = (a: unknown) => Array.isArray(a) && a.length ? (a as string[]).join(', ') : '—';
    const context = [
      `Exercise: ${ex.name}`,
      `Category: ${ex.category ?? '—'}`,
      `Movement pattern: ${ex.movement_pattern ?? '—'}`,
      `Type: ${ex.exercise_type ?? '—'}`,
      `Difficulty: ${ex.difficulty ?? '—'}`,
      `Primary muscles: ${list(ex.primary_muscles)}`,
      `Secondary muscles: ${list(ex.secondary_muscles)}`,
      `Equipment: ${list(ex.equipment_required)}`,
    ].join('\n');

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-6',
        max_tokens: 1500,
        system: SYSTEM,
        messages: [{ role: 'user', content: `Generate coaching content for:\n${context}` }],
      }),
    });
    if (!res.ok) {
      const err = await res.text();
      console.error('Anthropic error:', res.status, err);
      return json({ error: 'AI request failed' }, 502);
    }

    const data = await res.json() as { content?: Array<{ text: string }> };
    let text = data.content?.[0]?.text ?? '{}';
    text = text.trim().replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start >= 0 && end > start) text = text.slice(start, end + 1);

    let ai: Record<string, unknown>;
    try { ai = JSON.parse(text); }
    catch { return json({ error: 'Could not read AI result', raw: text }, 502); }

    // Full record = existing metadata + AI content → re-seed (idempotent by slug).
    const record = {
      exercise_name: ex.name,
      slug: ex.slug,
      category: ex.category,
      difficulty: ex.difficulty,
      movement_pattern: ex.movement_pattern,
      exercise_type: ex.exercise_type,
      primary_muscles: ex.primary_muscles ?? [],
      secondary_muscles: ex.secondary_muscles ?? [],
      equipment_required: ex.equipment_required ?? [],
      body_region: ex.body_region ?? [],
      goal_tags: ex.goal_tags ?? [],
      supports_pr_tracking: ex.supports_pr_tracking,
      supports_rpe_tracking: ex.supports_rpe_tracking,
      description: ai.description ?? ex.description,
      step_by_step_instructions: ai.step_by_step_instructions ?? [],
      coaching_cues: ai.coaching_cues ?? {},
      common_mistakes: ai.common_mistakes ?? [],
      alternative_exercises: ai.alternative_exercises ?? [],
      breathing: ai.breathing ?? {},
      ai_exercise_tips: ai.ai_exercise_tips ?? {},
    };

    const { error: seedErr } = await userDb.rpc('seed_exercise', {
      p: record, p_coach_id: ex.coach_id,
    });
    if (seedErr) {
      console.error('seed_exercise error:', seedErr);
      return json({ error: 'Failed to save enrichment', detail: seedErr.message }, 500);
    }

    return json({ result: ai, slug: ex.slug });
  } catch (e) {
    console.error('enrich-exercise error:', e);
    return json({ error: String(e) }, 500);
  }
});
