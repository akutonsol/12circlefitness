// Bulk AI content enrichment for the GLOBAL exercise library (the `exercises`
// table — the one the app actually reads; `custom_exercises` is empty and the
// older single-slug enrich-exercise fn targets it, so it never fills these rows).
//
// For each stub exercise (missing instructions), Claude writes accurate coaching
// content — instructions, cues, common mistakes, beginner/advanced variants,
// alternatives — matching the column SHAPES already used by the seeded 22
// exercises (flat string arrays + singular text). Coach/admin only. Idempotent:
// skips exercises that already have instructions unless force=true.
//
// Required secret:  supabase secrets set ANTHROPIC_API_KEY=...
// Invoke (loop batches from the admin UI, like the video enricher):
//   functions.invoke('enrich-exercise-content', body: { limit: 15, force: false })
//   functions.invoke('enrich-exercise-content', body: { ids: ['<uuid>', ...] })
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

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
  "instructions": ["imperative step-by-step cue (max ~16 words)", "..."],
  "coaching_cues": ["short form cue", "..."],
  "common_mistakes": ["the mistake → why it matters / the fix", "..."],
  "beginner_modification": "one sentence making it easier / more accessible",
  "advanced_progression": "one sentence making it harder / progressing it",
  "alternatives": ["Widely-Known Exercise Name", "..."],
  "confidence": 0-100 integer — your confidence this content is accurate and complete
}
Give 4-7 instructions, 3-4 coaching_cues, 2-4 common_mistakes, and 3-5 alternatives
(use widely-known exercise names training the same movement pattern so they can link
to the library). For isometric/stretch/cardio/mobility exercises adapt sensibly.
Never invent equipment not implied by the metadata.`;

const asArr = (v: unknown): string[] =>
  Array.isArray(v) ? v.map((x) => String(x)).filter(Boolean) : [];
const asStr = (v: unknown): string | null =>
  typeof v === 'string' && v.trim() ? v.trim() : null;

async function generate(ex: Record<string, any>): Promise<Record<string, unknown> | null> {
  const list = (a: unknown) => Array.isArray(a) && a.length ? (a as string[]).join(', ') : '—';
  const context = [
    `Exercise: ${ex.name}`,
    `Category: ${ex.category ?? '—'}`,
    `Primary muscle: ${ex.muscle_group ?? '—'}`,
    `Secondary muscles: ${list(ex.secondary_muscles)}`,
    `Equipment: ${ex.equipment ?? list(ex.equipment_required)}`,
    `Difficulty: ${ex.difficulty ?? '—'}`,
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
      max_tokens: 1200,
      system: SYSTEM,
      messages: [{ role: 'user', content: `Generate coaching content for:\n${context}` }],
    }),
  });
  if (!res.ok) throw new Error(`anthropic ${res.status}: ${(await res.text()).slice(0, 160)}`);
  const data = await res.json() as { content?: Array<{ text: string }> };
  let text = data.content?.[0]?.text ?? '{}';
  text = text.trim().replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
  const s = text.indexOf('{'), e = text.lastIndexOf('}');
  if (s >= 0 && e > s) text = text.slice(s, e + 1);
  try { return JSON.parse(text); } catch { return null; }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);
    if (!ANTHROPIC_API_KEY) return json({ error: 'AI not configured (set ANTHROPIC_API_KEY)' }, 500);
    if (!SERVICE_ROLE_KEY)  return json({ error: 'Server not configured' }, 500);

    const { data: profile } = await userDb
      .from('user_profiles').select('role').eq('id', user.id).single();
    if (!profile || !['coach', 'admin'].includes(profile.role as string)) {
      return json({ error: 'Forbidden' }, 403);
    }

    const body = await req.json().catch(() => ({})) as
      { ids?: string[]; limit?: number; force?: boolean };
    const force = body.force === true;
    // Keep each call well inside the edge-function wall-clock (Claude ~2-4s each).
    const limit = Math.min(Math.max(body.limit ?? 15, 1), 25);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const cols = 'id,name,category,muscle_group,secondary_muscles,equipment,equipment_required,difficulty,instructions';

    // Target set: explicit ids, else the next batch of stubs (no instructions).
    let targets: Record<string, any>[] = [];
    if (body.ids?.length) {
      const { data } = await admin.from('exercises').select(cols).in('id', body.ids);
      targets = data ?? [];
    } else {
      const q = admin.from('exercises').select(cols).limit(limit);
      const { data } = force ? await q : await q.is('instructions', null);
      targets = data ?? [];
    }
    if (!force) targets = targets.filter((t) => asArr(t.instructions).length === 0);

    let updated = 0, failed = 0, skipped = 0;
    const results: any[] = [];
    for (const ex of targets.slice(0, limit)) {
      try {
        const ai = await generate(ex);
        if (!ai) { failed++; results.push({ id: ex.id, name: ex.name, error: 'unparseable' }); continue; }
        const confidence = Math.max(0, Math.min(100, Number(ai.confidence) || 0));
        // Editorial workflow: AI content is a review candidate, not live content.
        // High confidence auto-approves; otherwise it queues for a human editor.
        const contentStatus = confidence > 90 ? 'approved' : 'under_review';
        const patch: Record<string, unknown> = {
          instructions: asArr(ai.instructions),
          coaching_cues: asArr(ai.coaching_cues),
          common_mistakes: asArr(ai.common_mistakes),
          beginner_modification: asStr(ai.beginner_modification),
          advanced_progression: asStr(ai.advanced_progression),
          alternatives: asArr(ai.alternatives),
          ai_confidence: confidence,
          content_status: contentStatus,
          updated_at: new Date().toISOString(),
        };
        if ((patch.instructions as string[]).length === 0) {
          skipped++; results.push({ id: ex.id, name: ex.name, skipped: 'empty result' }); continue;
        }
        const { error } = await admin.from('exercises').update(patch).eq('id', ex.id);
        if (error) { failed++; results.push({ id: ex.id, name: ex.name, error: error.message }); continue; }
        // Snapshot this AI draft as a content version (roll-back + audit trail).
        await admin.rpc('snapshot_exercise_content', {
          p_id: ex.id, p_source: 'ai_generated', p_confidence: confidence, p_actor: user.id,
        });
        updated++;
        results.push({ id: ex.id, name: ex.name, ok: true, confidence, status: contentStatus });
      } catch (err) {
        failed++; results.push({ id: ex.id, name: ex.name, error: String(err).slice(0, 160) });
      }
    }

    // How much of the library still needs work (so the UI can show progress).
    const { count: totalStubs } = await admin.from('exercises')
      .select('id', { count: 'exact', head: true }).is('instructions', null);

    return json({ processed: targets.length, updated, failed, skipped, remaining_stubs: totalStubs, results });
  } catch (e) {
    console.error('enrich-exercise-content error:', e);
    return json({ error: String(e).slice(0, 200) }, 500);
  }
});
