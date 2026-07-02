// L4 Communication Layer — narrates a DETERMINISTIC decision trace into human
// language. The engine already decided; the LLM only EXPLAINS. It is hard-
// constrained: it may use ONLY the recorded trace (selected/rejected exercises,
// triggered rules, reasons, context). It must never invent reasoning, and if
// asked about anything not in the trace it says it wasn't recorded.
//
// Required: supabase secrets set ANTHROPIC_API_KEY=...
// Invoke: functions.invoke('explain-decision', body:{ trace_id, audience:'client'|'coach' })
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const MODEL = 'claude-sonnet-4-6';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (d: unknown, s = 200) =>
  new Response(JSON.stringify(d), { status: s, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

const SYSTEM = `You explain a fitness workout decision that has ALREADY been made
by a deterministic engine. You are a communication layer, not a decision-maker.

HARD RULES — non-negotiable:
- Use ONLY the facts in the provided Decision Trace (selected exercises, rejected
  exercises with their rule + reason, triggered rules, recovery/goal context,
  warm-up). Do NOT introduce exercises, muscles, reasons, or numbers not present.
- Never invent physiology or justifications. If the trace doesn't contain a
  reason, do not manufacture one.
- If the requested explanation would require information not in the trace, say
  plainly that it wasn't recorded in this decision.
- Do not contradict the trace (e.g. never say an exercise was included if it was
  rejected).

Return 2-5 short sentences. No markdown headers, no lists unless natural.`;

function buildContext(t: any, audience: string): string {
  const ctx = t.context ?? {};
  const result = t.result ?? {};
  const trace = Array.isArray(t.trace) ? t.trace : [];
  const accepted = trace.filter((e: any) => e.decision === 'accepted').map((e: any) => e.name);
  const rejected = trace.filter((e: any) => e.decision === 'rejected')
    .map((e: any) => `${e.name} (rejected — ${e.rule}: ${e.reason})`);
  const warmup = Array.isArray(result.warmup) ? result.warmup.map((w: any) => w.name) : [];
  const lines = [
    `Audience: ${audience}`,
    `Goal: ${ctx.goal ?? 'unspecified'}`,
    `Recovery score: ${ctx.recovery ?? 'unspecified'}`,
    `Volume factor: ${result.volume_factor ?? 1}`,
    `Rules triggered: ${(t.rules_triggered ?? []).join(', ') || 'none'}`,
    `Selected exercises: ${accepted.join(', ') || 'none'}`,
    `Rejected candidates: ${rejected.length ? rejected.join('; ') : 'none'}`,
    `Warm-up: ${warmup.join(', ') || 'none'}`,
  ];
  const framing = audience === 'client'
    ? `Write a warm, first-person message from coach to client explaining today's workout and any swaps, in plain language.`
    : `Write a concise technical rationale for a coach reviewing why the engine built this workout.`;
  return `${framing}\n\nDecision Trace:\n${lines.join('\n')}`;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);
    if (!ANTHROPIC_API_KEY) return json({ error: 'AI not configured' }, 500);

    const body = await req.json().catch(() => ({})) as { trace_id?: string; audience?: string };
    const audience = body.audience === 'coach' ? 'coach' : 'client';
    if (!body.trace_id) return json({ error: 'Provide trace_id' }, 400);

    // Read the trace under the caller's RLS (they can only explain what they can see).
    const { data: t, error } = await userDb.from('decision_traces')
      .select('id, context, result, trace, rules_triggered, explanation_client, explanation_coach')
      .eq('id', body.trace_id).maybeSingle();
    if (error || !t) return json({ error: 'Trace not found' }, 404);

    // Serve cached explanation if present.
    const cached = audience === 'coach' ? t.explanation_coach : t.explanation_client;
    if (cached) return json({ explanation: cached, audience, cached: true });

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: MODEL, max_tokens: 500, system: SYSTEM,
        messages: [{ role: 'user', content: buildContext(t, audience) }] }),
    });
    if (!res.ok) return json({ error: `AI request failed (${res.status})` }, 502);
    const data = await res.json() as { content?: Array<{ text: string }> };
    const explanation = (data.content?.[0]?.text ?? '').trim();
    if (!explanation) return json({ error: 'Empty explanation' }, 502);

    // Cache on the trace (service role — bypasses RLS for the write).
    if (SERVICE_ROLE_KEY) {
      const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
      await admin.from('decision_traces').update({
        [audience === 'coach' ? 'explanation_coach' : 'explanation_client']: explanation,
        explained_at: new Date().toISOString(), explain_model: MODEL,
      }).eq('id', body.trace_id);
    }
    return json({ explanation, audience, cached: false });
  } catch (e) {
    console.error('explain-decision error:', e);
    return json({ error: String(e).slice(0, 200) }, 500);
  }
});
