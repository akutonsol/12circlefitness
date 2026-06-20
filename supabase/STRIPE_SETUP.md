# Stripe Setup Runbook (Test Mode)

Everything in code is done. This is the account/config wiring. Price IDs below
are **test-mode** and safe to commit. The **secret key** and **webhook secret**
are NOT — they are set only via `supabase secrets set`, never committed.

Project ref: `nxdbooufqzkpslkcogxc`

## 1. Install + link the CLI (one-time)
```bash
brew install supabase/tap/supabase
supabase link --project-ref nxdbooufqzkpslkcogxc
```

## 2. Set secrets
Fill in `sk_test_…` from Stripe → Developers → API keys. The 5 price IDs are
pre-filled. (`SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY`
are auto-injected into Edge Functions — no need to set them.)
```bash
supabase secrets set \
  STRIPE_SECRET_KEY=sk_test_REPLACE_ME \
  STRIPE_SELF_GUIDED_PRICE_ID=price_1TjZCVLwsDN0E0HCeNKdbtf4 \
  STRIPE_AI_GUIDED_PRICE_ID=price_1TjZDZLwsDN0E0HCXqsuqHNR \
  STRIPE_COACH_STARTER_PRICE_ID=price_1TjZEFLwsDN0E0HC9QfbZ45b \
  STRIPE_COACH_GROWTH_PRICE_ID=price_1TjZFCLwsDN0E0HCRO7F6xVL \
  STRIPE_COACH_ELITE_PRICE_ID=price_1TjZG4LwsDN0E0HCraYmgYYa
```

## 3. Deploy the three functions
```bash
supabase functions deploy create-checkout
supabase functions deploy create-portal-session
supabase functions deploy stripe-webhook --no-verify-jwt   # Stripe sends no Supabase JWT
```

## 4. Configure the webhook
1. Copy the deployed URL of `stripe-webhook` (Supabase Dashboard → Edge Functions),
   e.g. `https://nxdbooufqzkpslkcogxc.supabase.co/functions/v1/stripe-webhook`
2. Stripe → Developers → Webhooks → Add endpoint → paste that URL.
3. Select events:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
4. Copy the signing secret (`whsec_…`) and set it:
```bash
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_REPLACE_ME
```

## 5. Test mode end-to-end
- Use Stripe test card `4242 4242 4242 4242`, any future expiry/CVC.
- Self-Guided / AI-Guided: tap the directory Premium banner → Upgrade → checkout.
- Coach plan: Coach Dashboard → tools → My Plan.
- Paid event ticket: open a non-free event → Buy Ticket.
- After paying, the `stripe-webhook` updates `subscriptions` / `payments`;
  pull-to-refresh the screen to see the new state.

## Notes
- Coach marketplace commission (10–15% on marketplace leads) needs **Stripe
  Connect** (coaches as connected accounts). Not built yet — current coach subs
  charge to the platform account.
