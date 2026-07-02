// L8 Coaching Communication Engine — translates a DETERMINISTIC grounding brief
// into coach + client language. It performs NO analysis: it may only phrase the
// facts already in the brief (week summary, wins, program changes, goal progress,
// predictions). It must not invent numbers, reasons, or outcomes, and must say
// nothing the brief doesn't contain. The coach edits before sending.
//
// Required: supabase secrets set ANTHROPIC_API_KEY=...
// Invoke: functions.invoke('generate-communication', body:{ communication_id })
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const LLM_VERSION = 'comm-1.0.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (d: unknown, s = 200) =>
  new Response(JSON.stringify(d), { status: s, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

const SYSTEM = `You write coaching communications for a fitness platform. The
decisions and numbers were ALREADY produced by deterministic engines. You are a
presentation layer, not an analyst.

HARD RULES:
- Use ONLY the facts in the provided BRIEF (week summary, wins, program changes,
  goal progress, predictions/alerts). Never introduce numbers, reasons, exercises,
  dates, or outcomes not in the brief.
- Never invent analysis or physiology. If the brief lacks something, omit it.
- Do not contradict the brief. Do not overstate ("guaranteed", "definitely").

Return ONLY JSON (no fences):
{ "client_text": "...", "coach_text": "..." }
- client_text: warm, encouraging, first-person coach→client. 4-8 sentences.
  Cover wins, progress toward goal, any program changes (plainly), and next-week
  focus if implied by predictions/alerts.
- coach_text: concise, clinical. Compliance/recovery, adaptations made, risk
  factors from predictions, and recommended actions. Bullet-like sentences.`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);
    if (!ANTHROPIC_API_KEY) return json({ error: 'AI not configured' }, 500);

    const body = await req.json().catch(() => ({})) as { communication_id?: string };
    if (!body.communication_id) return json({ error: 'Provide communication_id' }, 400);

    const { data: comm, error } = await userDb.from('communications')
      .select('id, type, brief, client_text, coach_text').eq('id', body.communication_id).maybeSingle();
    if (error || !comm) return json({ error: 'Communication not found' }, 404);
    if (comm.client_text) return json({ client_text: comm.client_text, coach_text: comm.coach_text, cached: true });

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'claude-sonnet-4-6', max_tokens: 900, system: SYSTEM,
        messages: [{ role: 'user', content: `Type: ${comm.type}\nBRIEF:\n${JSON.stringify(comm.brief, null, 2)}` }] }),
    });
    if (!res.ok) return json({ error: `AI request failed (${res.status})` }, 502);
    const data = await res.json() as { content?: Array<{ text: string }> };
    let t = (data.content?.[0]?.text ?? '{}').trim().replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
    const s = t.indexOf('{'), e = t.lastIndexOf('}');
    if (s >= 0 && e > s) t = t.slice(s, e + 1);
    let out: { client_text?: string; coach_text?: string };
    try { out = JSON.parse(t); } catch { return json({ error: 'Could not parse result' }, 502); }
    if (!out.client_text && !out.coach_text) return json({ error: 'Empty communication' }, 502);

    // Persist as draft text (service role); coach edits before sending.
    if (SERVICE_ROLE_KEY) {
      const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
      await admin.from('communications').update({
        client_text: out.client_text ?? '', coach_text: out.coach_text ?? '', llm_version: LLM_VERSION,
      }).eq('id', body.communication_id);
    }
    return json({ client_text: out.client_text, coach_text: out.coach_text, cached: false });
  } catch (e) {
    console.error('generate-communication error:', e);
    return json({ error: String(e).slice(0, 200) }, 500);
  }
});
