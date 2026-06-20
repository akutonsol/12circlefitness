// Sends a real invite email (via Resend) when a coach invites a client or a
// team member. The app inserts the invite row, then calls this to deliver the
// email. Auth required (the inviting coach).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? '';
const APP_URL = Deno.env.get('APP_URL') ?? 'https://12circle.app';
// Set EMAIL_FROM to an address on a domain you've verified in Resend to send to
// any recipient. Defaults to Resend's shared sender (testing-only: it can only
// deliver to your own verified Resend account email).
const EMAIL_FROM = Deno.env.get('EMAIL_FROM') ?? '12 Circle Fitness <onboarding@resend.dev>';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (d: unknown, s = 200) =>
  new Response(JSON.stringify(d), { status: s, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);

    const { email, type, token } = await req.json() as {
      email: string; type: 'client' | 'team'; token?: string;
    };
    if (!email) return json({ error: 'email required' }, 400);
    if (!RESEND_API_KEY) return json({ error: 'Email not configured' }, 500);

    const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: coach } = await db
      .from('user_profiles')
      .select('first_name, last_name, email')
      .eq('id', user.id)
      .maybeSingle();
    const coachName = [coach?.first_name, coach?.last_name].filter(Boolean).join(' ') || 'Your coach';
    const coachEmail = coach?.email as string | undefined;

    const isTeam = type === 'team';
    const joinUrl = `${APP_URL}/#/signup${token ? `?invite=${token}` : ''}`;
    const subject = isTeam
      ? `${coachName} invited you to their coaching team on 12 Circle`
      : `${coachName} invited you to train on 12 Circle`;
    const heading = isTeam ? 'Join the coaching team 🤝' : 'Your coach is waiting 💪';
    const blurb = isTeam
      ? `${coachName} has invited you to join their coaching team on 12 Circle Fitness.`
      : `${coachName} has invited you to train with them on 12 Circle Fitness. Create your account to start your personalised program.`;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: EMAIL_FROM,
        to: [email],
        ...(coachEmail ? { reply_to: coachEmail } : {}),
        subject,
        html: `
          <div style="font-family:sans-serif;max-width:520px;margin:0 auto;background:#0E0B16;color:#E5E2E3;padding:32px;border-radius:12px;">
            <h2 style="color:#DDB7FF;margin:0 0 8px">${heading}</h2>
            <p style="color:#CFC2D6;">${blurb}</p>
            <div style="margin:28px 0;text-align:center;">
              <a href="${joinUrl}" style="display:inline-block;background:#A855F7;color:#fff;text-decoration:none;padding:14px 28px;border-radius:10px;font-weight:700;">Accept Invite</a>
            </div>
            <p style="color:#968E99;font-size:13px;">Or open this link: <a href="${joinUrl}" style="color:#DDB7FF;">${joinUrl}</a></p>
            <p style="color:#4B444F;font-size:12px;margin:24px 0 0;">12 Circle Fitness</p>
          </div>
        `,
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      console.error('Resend error:', err);
      return json({ error: 'Email send failed', detail: err }, 502);
    }
    return json({ sent: true });
  } catch (e) {
    console.error('send-invite-email error:', e);
    return json({ error: String(e) }, 500);
  }
});
