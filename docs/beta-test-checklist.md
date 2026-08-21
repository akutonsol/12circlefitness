# 12 Circle — Full Manual Test Checklist

Walk it top to bottom. Each item: **do → expect**. Mark ✅ / ❌ / ⚠️ and note
anything that surprises you. Tags: `[ACT]` needs activation · `[2ACCT]` needs a
coach+client pair · `[DEVICE]` phone/mic only · `[DEBUG]` debug build only.

---

## Phase 0 — Activation (do this first, or most of the app is dormant)

- [ ] Apply migrations **082 → 099** in order (Supabase SQL). → no errors.
- [ ] Set secrets: `ANTHROPIC_API_KEY`, `YOUTUBE_API_KEY`, Stripe keys, email. 
- [ ] Deploy edge functions: `enrich-exercise-content`, `enrich-exercise-intelligence`,
      `enrich-exercise-videos`, `explain-decision`, `generate-communication`,
      `enrich-exercise`, `create-checkout`, `stripe-connect`, `stripe-webhook`.
- [ ] Create test accounts: **client**, **coach**, **admin** (+ a 2nd client helps).
- [ ] Make the coach↔client active: coach accepts/【client requests】 → relationship `active`.
- [ ] Content Center → **Rebuild graph** → **AI-enrich content** → **AI-enrich
      intelligence** → **Knowledge Review (approve some)** → **Seed warm-up library**.
- [ ] QA Center (`/qa-center`, `[DEBUG]`) → Run All → **Release Certification green**.

## Phase 1 — Auth & onboarding

- [ ] Sign up a new client → complete intake (goals, activities, height/weight, etc.).
      → each answer persists; lands on home.
- [ ] Log out (each role) → returns to login cleanly (no stale identity).
- [ ] Log in as client / coach / admin → each lands on the correct home/dashboard.
- [ ] Switch coaching mode (client) → home + subscription screen reflect the new mode.

## Phase 2 — Client experience

- [ ] Home / dashboard → renders; score card, quick grid, coach tip.
- [ ] Train hub → shows client's program/habits (not coach screens).
- [ ] Active workout → start a set; **rest timer** counts down; let it hit 0 →
      **negative overtime countdown** + siren; entering next set stops it.
- [ ] Swap exercise → suggests the **correct same-pattern substitute** (not random),
      sheet scrolls, better swap icon.
- [ ] Nutrition → gated by plan (`[ACT]`); can scroll back **>5 days** in the date strip.
- [ ] Habits · Progress · Scoring (`/score`) → load and record.
- [ ] Community · Challenges → load.
- [ ] Exercise library → open an exercise → detail page renders.
- [ ] Paywall: as a **free** client, a paid feature → shows upgrade, not a crash.

## Phase 3 — Coach media (the new layer) `[2ACCT]`

**As coach**, open an exercise detail:
- [ ] "YOUR COACHING" → **Add** → enter Coach Focus bullets + note + video link → Save.
- [ ] Reopen → **Apply a pack** (if you have one) / **Save these as a pack** (name it).
- [ ] Open another squat variation → the pack shows under **Suggested Packs** with a %.
- [ ] Voice `[DEVICE]` → **hold to record** ~15s → release → uploads; player appears.
- [ ] Set expiry **This week**; save.

**As the client** (assigned to that coach), open the same exercise:
- [ ] Order is exactly: **coach name → 🎤 voice → Coach Focus → note → coach video →
      official video → official instructions**.
- [ ] Tap voice → plays; waveform fills.
- [ ] (Later) let voice expire → it disappears; **official content remains**.

## Phase 4 — Coach experience (the engine) `[ACT]` `[2ACCT]`

Coach dashboard → tools sheet:
- [ ] **Copilot** → pick a client → **Client Outlook** (goal %, confidence, risks) →
      **Generate recommendation** → selected exercises + WHY (swaps/reasons) + warm-up
      → **Explain for coach** → **Approve & assign**. → client's program updates.
- [ ] **Program AI** → set strategy → **Plan** → mesocycles + week timeline (deloads at
      4/8/12) → **Create program (v1)**.
- [ ] **Adapt** (Continuous Coaching) → pick program + week → set feedback (low recovery
      / pain) → **Evaluate** → recommendation + approval-by-mode → **Approve & regenerate**
      → **Program Diff** shows only future weeks changed.
- [ ] **Reviews** → pick program + client + week → **Generate** → grounding brief +
      editable client/coach text → edit → **Send**. → client can see it (sent only).

## Phase 5 — Content & knowledge (coach/admin) `[ACT]`

- [ ] Content Center → **Content quality** bars, **Module Certification**,
      **Movement Intelligence Engine** (nodes/edges), **Programming Intelligence**.
- [ ] **Knowledge Review** (`/knowledge-review`) → a profile → per-attribute
      Approve/Edit/Reject → **Finalize** → status becomes approved when all resolved.
- [ ] **MIE Debugger** (`/mie-debugger`) → set context → **Generate & trace** →
      candidates accepted/rejected with rules → **Explain** (client/coach).
- [ ] Exercise Content Center → **AI-enrich** runs batches; **Rebuild** graph/intelligence;
      **Seed warm-up library**.

## Phase 6 — Admin & QA `[DEBUG]`

- [ ] Admin dashboard → **Global Library Review**, **Exercise Content Center**,
      **Coaching Observability**.
- [ ] **Coaching Observability** (`/observability`) → KPI grid (programs, traces,
      predictions, reviews, adherence, cert %). Zeros before real usage = expected.
- [ ] **QA Center** → run every group (Coaching Modes, Entitlements, Data Integrity,
      Content Quality, User Journeys) → Release gate reflects results.

## Phase 7 — Payments `[ACT]`

- [ ] Upgrade flow → Stripe test checkout → success → plan/entitlement updates
      (`client_plan` reflects new tier; paywalled screens unlock).
- [ ] Cancel / manage subscription → status updates.

## Phase 8 — Edge & error states

- [ ] Kill network mid-action → graceful error, no crash.
- [ ] Open a screen whose migration isn't applied → "apply migration 0XX" banner,
      not a blank/crash.
- [ ] Free client hits AI Coach / coach messaging → paywall, not error.

---

### Report format (per issue)
`Phase · Screen · Role · Severity (Critical/High/Med/Low) · what you did → what happened`
→ each ⚠️/❌ becomes a Beta Feedback Board row.
