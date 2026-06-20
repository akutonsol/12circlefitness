// Returns a Stripe Customer Portal URL so a user can manage / cancel their
// subscriptions and payment methods. Auth required; uses the customer id we
// stored on their profile.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@16.12.0?target=deno';

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') ?? '';
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
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);

    const { returnUrl } = await req.json().catch(() => ({})) as { returnUrl?: string };

    const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: profile } = await db
      .from('user_profiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .maybeSingle();

    const customerId = profile?.stripe_customer_id as string | null;
    if (!customerId) return json({ error: 'No billing account yet' }, 400);

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: returnUrl ?? 'https://12circle.app/account',
    });
    return json({ url: session.url });
  } catch (e) {
    console.error('create-portal-session error:', e);
    return json({ error: String(e) }, 500);
  }
});
