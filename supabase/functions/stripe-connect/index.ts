// Stripe Connect onboarding for coaches. A coach connects (or resumes onboarding
// of) an Express account so client coaching payments are charged directly to
// them, with 12 Circle taking only a commission. Auth required (the coach).
//   action 'onboard' → returns an Account Link URL to complete onboarding
//   action 'status'  → returns { connected, charges_enabled, payouts_enabled }
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@16.12.0?target=deno';

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') ?? '';
const APP_URL = Deno.env.get('APP_URL') ?? 'https://12circle.app';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2024-06-20',
  httpClient: Stripe.createFetchHttpClient(),
});

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
    if (!STRIPE_SECRET_KEY) return json({ error: 'Stripe not configured' }, 500);

    const { action, returnUrl } = await req.json() as { action: string; returnUrl?: string };
    const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: profile } = await db
      .from('user_profiles')
      .select('stripe_account_id, email, first_name, last_name, role')
      .eq('id', user.id)
      .maybeSingle();
    if (profile?.role !== 'coach') return json({ error: 'Only coaches can connect Stripe' }, 403);

    if (action === 'status') {
      const acct = profile?.stripe_account_id as string | null;
      if (!acct) return json({ connected: false, charges_enabled: false, payouts_enabled: false });
      const account = await stripe.accounts.retrieve(acct);
      await db.from('user_profiles').update({
        stripe_charges_enabled: account.charges_enabled ?? false,
        stripe_payouts_enabled: account.payouts_enabled ?? false,
      }).eq('id', user.id);
      return json({
        connected: true,
        charges_enabled: account.charges_enabled ?? false,
        payouts_enabled: account.payouts_enabled ?? false,
        details_submitted: account.details_submitted ?? false,
      });
    }

    if (action === 'balance') {
      const acct = profile?.stripe_account_id as string | null;
      if (!acct) return json({ pending: 0, available: 0 });
      // deno-lint-ignore no-explicit-any
      const sum = (arr: any[] | undefined) => (arr ?? []).reduce((s, b) => s + (b.amount ?? 0), 0);
      try {
        const bal = await stripe.balance.retrieve({}, { stripeAccount: acct });
        return json({ pending: sum(bal.pending), available: sum(bal.available) });
      } catch (_) {
        return json({ pending: 0, available: 0 });
      }
    }

    if (action === 'onboard') {
      let acct = profile?.stripe_account_id as string | null;
      if (!acct) {
        const account = await stripe.accounts.create({
          type: 'express',
          email: profile?.email ?? user.email ?? undefined,
          capabilities: { transfers: { requested: true }, card_payments: { requested: true } },
          business_type: 'individual',
          metadata: { supabase_user_id: user.id },
        });
        acct = account.id;
        await db.from('user_profiles').update({ stripe_account_id: acct }).eq('id', user.id);
      }
      const back = returnUrl ?? `${APP_URL}/#/coach-payments`;
      const link = await stripe.accountLinks.create({
        account: acct,
        refresh_url: back,
        return_url: back,
        type: 'account_onboarding',
      });
      return json({ url: link.url, accountId: acct });
    }

    return json({ error: 'Unknown action' }, 400);
  } catch (e) {
    console.error('stripe-connect error:', e);
    return json({ error: String(e) }, 500);
  }
});
