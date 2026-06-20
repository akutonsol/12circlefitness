import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') ?? '';
const SUPABASE_URL   = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  const body = await req.json().catch(() => ({}));
  const clientName  = body.client_name  as string | undefined;
  const clientEmail = body.client_email as string | undefined;
  const clientId    = body.client_id    as string | undefined;

  if (!clientName) {
    return new Response(JSON.stringify({ error: 'missing client_name' }), { status: 400 });
  }

  // Fetch all coach emails from user_profiles
  const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const { data: coaches, error } = await db
    .from('user_profiles')
    .select('email, first_name')
    .eq('role', 'coach');

  if (error || !coaches?.length) {
    return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
  }

  // Send one email per coach via Resend
  const sends = coaches.map(async (coach: { email: string; first_name?: string }) => {
    const coachName = coach.first_name ?? 'Coach';
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: '12 Circle Fitness <onboarding@resend.dev>',
        to: [coach.email],
        subject: `New Client: ${clientName} has completed onboarding`,
        html: `
          <div style="font-family:sans-serif;max-width:520px;margin:0 auto;background:#0E0B16;color:#E5E2E3;padding:32px;border-radius:12px;">
            <h2 style="color:#DDB7FF;margin:0 0 8px">New Client Signed Up 🎉</h2>
            <p style="color:#CFC2D6;margin:0 0 20px">Hi ${coachName},</p>
            <p style="color:#CFC2D6;">
              <strong style="color:#fff">${clientName}</strong> has just completed onboarding
              and is ready to start their fitness journey with you.
            </p>
            ${clientEmail ? `<p style="color:#968E99;font-size:13px;">Client email: ${clientEmail}</p>` : ''}
            <div style="margin:28px 0;padding:20px;background:#1A1020;border-radius:8px;border-left:3px solid #A855F7;">
              <p style="margin:0;color:#CFC2D6;font-size:14px;">Log in to your coach dashboard to view their profile and begin customising their program.</p>
            </div>
            <p style="color:#4B444F;font-size:12px;margin:0;">12 Circle Fitness · This is an automated notification.</p>
          </div>
        `,
      }),
    });
    return res.ok;
  });

  const results = await Promise.allSettled(sends);
  const sent = results.filter((r) => r.status === 'fulfilled' && r.value).length;

  return new Response(JSON.stringify({ sent, total: coaches.length }), {
    headers: { 'Content-Type': 'application/json' },
    status: 200,
  });
});
