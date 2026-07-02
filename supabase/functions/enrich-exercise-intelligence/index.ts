// Knowledge Enrichment Pipeline (MIE Phase 2b). Claude drafts the FULL exercise
// intelligence profile — programming goal fit, biomechanics, per-joint loading,
// fatigue, and coaching metadata — WITH PER-ATTRIBUTE CONFIDENCE, so reviewers
// only certify the low-confidence attributes. Writes to exercise_intelligence
// as status='ai_generated' (goes through the human review pipeline). The
// deterministic scoring engine is unchanged — only its inputs improve.
//
// Required: supabase secrets set ANTHROPIC_API_KEY=...
// Invoke (loop batches): functions.invoke('enrich-exercise-intelligence', body:{limit:10})
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const AI_VERSION = 'intel-1.0.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (d: unknown, s = 200) =>
  new Response(JSON.stringify(d), { status: s, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

const SYSTEM = `You are a strength & conditioning scientist assigning STRUCTURED
programming metadata to an exercise. All scores are integers 0-10 unless noted.
Respond with ONLY this JSON object (no prose, no fences):
{
  "goals": {"strength":0,"hypertrophy":0,"power":0,"endurance":0,"fat_loss":0,
            "athletic":0,"functional":0,"rehab":0,"general_health":0,"senior":0,"postpartum":0,"youth":0},
  "fatigue": {"local":0,"systemic":0,"recovery_cost":0,"neurological":0,"technical":0},
  "skill": {"technical_complexity":0,"coordination":0,"balance":0,"mobility_requirement":0},
  "joint_stress": {"knee":0,"hip":0,"lower_back":0,"shoulder":0,"elbow":0,"wrist":0},
  "loading": {"spinal":0,"shoulder":0,"hip":0,"knee":0,"grip":0,"core":0,"cardio":0},
  "biomechanics": {"plane_of_motion":"sagittal|frontal|transverse","unilateral":false,
                   "closed_chain":false,"force_vector":"vertical|horizontal|lateral","stability_requirement":0},
  "energy_systems": ["atp_pc","lactic","aerobic"],
  "rep_ranges": {"strength":"3-6","hypertrophy":"6-12","endurance":"15-20"},
  "frequency_per_week": 2,
  "min_experience": "beginner|intermediate|advanced",
  "contraindications": ["short phrase", "..."],
  "coaching": {"top_cue":"", "common_errors":["..."], "regression_priority":"Exercise Name",
               "progression_priority":"Exercise Name", "teaching_complexity":0,
               "safety_notes":"", "spotter_required":false, "common_compensations":["..."]},
  "confidence": {"joint_stress":0,"fatigue":0,"contraindications":0,"rep_ranges":0,
                 "programming_goals":0,"biomechanics":0,"loading":0,"coaching":0}
}
Base every value on the exercise's biomechanics. Be conservative with confidence:
only give >90 when the value is well-established; lower it when you are inferring.`;

const iv = (v: unknown, d = 0) => { const n = Math.round(Number(v)); return Number.isFinite(n) ? Math.max(0, Math.min(10, n)) : d; };
const cv = (v: unknown) => { const n = Math.round(Number(v)); return Number.isFinite(n) ? Math.max(0, Math.min(100, n)) : 0; };
const asArr = (v: unknown): string[] => Array.isArray(v) ? v.map(String).filter(Boolean) : [];

async function generate(ex: Record<string, any>): Promise<Record<string, any> | null> {
  const list = (a: unknown) => Array.isArray(a) && a.length ? (a as string[]).join(', ') : '—';
  const ctx = [
    `Exercise: ${ex.name}`, `Category: ${ex.category ?? '—'}`,
    `Movement pattern: ${ex.movement_pattern ?? '—'}`, `Type: ${ex.exercise_type ?? '—'}`,
    `Primary muscle: ${ex.muscle_group ?? '—'}`, `Secondary: ${list(ex.secondary_muscles)}`,
    `Equipment: ${ex.equipment ?? '—'}`,
  ].join('\n');
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'claude-sonnet-4-6', max_tokens: 1400, system: SYSTEM,
      messages: [{ role: 'user', content: `Profile this exercise:\n${ctx}` }] }),
  });
  if (!res.ok) throw new Error(`anthropic ${res.status}: ${(await res.text()).slice(0, 160)}`);
  const data = await res.json() as { content?: Array<{ text: string }> };
  let t = (data.content?.[0]?.text ?? '{}').trim().replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
  const s = t.indexOf('{'), e = t.lastIndexOf('}');
  if (s >= 0 && e > s) t = t.slice(s, e + 1);
  try { return JSON.parse(t); } catch { return null; }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);
    if (!ANTHROPIC_API_KEY) return json({ error: 'AI not configured' }, 500);
    if (!SERVICE_ROLE_KEY) return json({ error: 'Server not configured' }, 500);
    const { data: profile } = await userDb.from('user_profiles').select('role').eq('id', user.id).single();
    if (!profile || !['coach', 'admin', 'content_manager'].includes(profile.role as string))
      return json({ error: 'Forbidden' }, 403);

    const body = await req.json().catch(() => ({})) as { ids?: string[]; limit?: number };
    const limit = Math.min(Math.max(body.limit ?? 10, 1), 20);
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const cols = 'id,name,category,muscle_group,secondary_muscles,equipment,movement_pattern,exercise_type';

    // Target: explicit ids, else exercises whose profile is still a derived draft (or missing).
    let targets: Record<string, any>[] = [];
    if (body.ids?.length) {
      targets = (await admin.from('exercises').select(cols).in('id', body.ids)).data ?? [];
    } else {
      const { data: drafts } = await admin.from('exercise_intelligence')
        .select('exercise_id').or('status.eq.draft,source.eq.derived').limit(limit);
      const ids = (drafts ?? []).map((d: any) => d.exercise_id);
      targets = ids.length ? ((await admin.from('exercises').select(cols).in('id', ids)).data ?? []) : [];
    }

    let updated = 0, failed = 0;
    const results: any[] = [];
    for (const ex of targets.slice(0, limit)) {
      try {
        const ai = await generate(ex);
        if (!ai) { failed++; results.push({ id: ex.id, name: ex.name, error: 'unparseable' }); continue; }
        const g = ai.goals ?? {}, f = ai.fatigue ?? {}, sk = ai.skill ?? {};
        const conf = ai.confidence ?? {};
        // Overall confidence = mean of per-attribute confidences.
        const cvals = Object.values(conf).map(cv);
        const overall = cvals.length ? Math.round(cvals.reduce((a: number, b: number) => a + b, 0) / cvals.length) : 0;
        const patch: Record<string, unknown> = {
          exercise_id: ex.id,
          goal_strength: iv(g.strength), goal_hypertrophy: iv(g.hypertrophy), goal_power: iv(g.power),
          goal_endurance: iv(g.endurance), goal_fat_loss: iv(g.fat_loss),
          local_fatigue: iv(f.local), systemic_fatigue: iv(f.systemic), recovery_cost: iv(f.recovery_cost),
          technical_complexity: iv(sk.technical_complexity), coordination: iv(sk.coordination),
          balance: iv(sk.balance), mobility_requirement: iv(sk.mobility_requirement),
          joint_stress: ai.joint_stress ?? {},
          energy_systems: asArr(ai.energy_systems),
          rep_ranges: ai.rep_ranges ?? {},
          frequency_per_week: Number.isFinite(Number(ai.frequency_per_week)) ? Number(ai.frequency_per_week) : null,
          min_experience: ['beginner', 'intermediate', 'advanced'].includes(ai.min_experience) ? ai.min_experience : 'beginner',
          contraindications: asArr(ai.contraindications),
          // rich profile + per-attribute confidence
          profile: { goals: g, fatigue: f, skill: sk, loading: ai.loading ?? {},
                     biomechanics: ai.biomechanics ?? {}, coaching: ai.coaching ?? {} },
          attribute_confidence: conf,
          confidence: overall,
          source: 'ai_generated', status: 'ai_generated',
          evidence_source: 'claude-sonnet-4-6', ai_version: AI_VERSION,
          updated_at: new Date().toISOString(),
        };
        const { error } = await admin.from('exercise_intelligence').upsert(patch, { onConflict: 'exercise_id' });
        if (error) { failed++; results.push({ id: ex.id, name: ex.name, error: error.message }); continue; }
        updated++; results.push({ id: ex.id, name: ex.name, confidence: overall });
      } catch (err) {
        failed++; results.push({ id: ex.id, name: ex.name, error: String(err).slice(0, 160) });
      }
    }
    const { count: remaining } = await admin.from('exercise_intelligence')
      .select('exercise_id', { count: 'exact', head: true }).or('status.eq.draft,source.eq.derived');
    return json({ processed: targets.length, updated, failed, remaining_drafts: remaining, results });
  } catch (e) {
    console.error('enrich-exercise-intelligence error:', e);
    return json({ error: String(e).slice(0, 200) }, 500);
  }
});
