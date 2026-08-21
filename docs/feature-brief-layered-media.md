# Feature Brief — Layered Exercise Media

**Status:** Candidate (Phase 2). Not built. Gated on the three-question rule below.
**Strengthens the Product Bible?** Yes — strongly. It *is* the platform
philosophy applied to media: **the platform certifies knowledge, the coach
personalizes it, the client experiences individualized coaching.**

---

## The problem

A generic exercise-video library (Trainerize-style) makes 12 Circle feel like an
exercise database, not a coaching platform. Dumping one canonical clip onto every
exercise is table stakes competitors can out-spend. The differentiator is
*personalization* — a client seeing *their coach* demonstrate *their* squat, with
cues aimed at *their* form.

## Why this is a moat

Volume of stock video is buyable. "Coach Julia recorded this for Emily, and it
references Emily's left knee" is not. It compounds over time into a living history
per client — the opposite of a static library.

## The layered model

Three authoring levels, resolved to the single highest-priority available:

| Level | Who authors | Scope | Example |
|-------|-------------|-------|---------|
| **1 · Official** | Platform | Global, canonical | Neutral, multi-angle Barbell Squat demo. |
| **2 · Coach** | A coach | That coach's clients | Julia's own squat demo + her written cues. |
| **3 · Client** | A coach, for one client | One client | 20-sec note: "Emily, push through your heel, slow the eccentric." |

**Resolution priority (per exercise, per viewer):**
`client-specific → coach version → official library → YouTube fallback`
→ there is always media; it just gets more personal as it exists.

Media is layered, not just video: official (video/images/cues/mistakes), coach
(video/voice/written cues/tips), client (personal reminder/form corrections/
voice note/previous issues).

## What already exists (so this is cheaper than it looks)

- `exercises` carries `video_variants`, `video_assets`, `image_assets`,
  `form_correction_videos`, `coach_id` — Level 1 + a coach's *own* exercises.
- `exercise_guide_sheet._resolveVideo` already resolves *coach upload → enriched
  YouTube → curated guide* — the resolution pattern is in place.
- `custom_exercise_service` has `findVideoForName`, `findEnrichedVideo`,
  `updateExerciseMedia`; `exercise_videos` is the YouTube fallback cache.

**Net-new:** per-coach overrides of *global* exercises (L2) and per-client media
(L3) — because today media lives on the exercise row, so only the owning coach can
override.

## Proposed data model (extend, don't rebuild)

Two small tables + a resolver:

```
coach_exercise_media   (coach_id, exercise_id, video, image, cues[], note,
                        reason, updated_at)          -- L2, PK (coach_id, exercise_id)
client_exercise_media  (coach_id, client_id, exercise_id, video, voice_url,
                        note, correction, created_at) -- L3
```

- RLS: coach reads/writes own rows; client reads only their own L3 + their coach's
  L2 + official.
- `resolve_exercise_media(exercise_id, viewer_id)` → the merged, highest-priority
  bundle the UI renders. One function; every screen calls it.

## "Why coach version?" (a small feature with outsized trust value)

When a client taps the coach/client video, show the coach's stated reasons:
`✓ Longer stance for your hips · ✓ Lower weight this week · ✓ Control the
eccentric · ✓ Prepping next week's progression`. This is the same instinct as the
rest of the platform — **explain the coaching** — applied to media.

## Phased build (smallest valuable first)

1. **L2 resolver + coach override** (highest leverage, most plumbing exists):
   `coach_exercise_media` + `resolve_exercise_media` + a "Record/replace this
   exercise for my clients" action in the coach exercise view. The client's
   exercise screen shows the coach's version when present.
2. **L3 client-specific** (the ⭐⭐⭐ differentiator): a coach records a 20-sec
   clip / voice note for one client on one exercise; only that client sees it.
   Needs a lightweight in-context record/upload UX.
3. **"Why coach version"** reasons + living history (previous attempts, PR
   history, before/after clips) on the exercise over time.

Do **not** pre-produce thousands of official videos before beta. Build the
resolver + coach/client layers; let the official library fill in over time.

## The three-question gate

1. **Problem:** generic media makes the app feel like a database, not coaching;
   it undercuts the core identity and the coach-client relationship.
2. **Evidence to build:** *(pending beta)* — a coach asks to use their own
   demos; clients ignore generic videos; "would you coach paying clients with
   this?" answers cite impersonal content. **Or** an explicit founder decision to
   treat it as identity-defining (like the measurement hooks were an exception).
3. **Success metric:** coach media-upload rate; % exercises with a coach/client
   override for active coaches; client engagement (views/opens) on coach/client
   videos vs official; retention of coaches who use it.

## Roadmap additions (captured, not yet built)

- **Smart Pack Updates** — packs are *templates* (each overlay owns a copy), which
  is correct. To offer "you changed Squat cues — update the 18 exercises it's
  applied to? (all / future only / leave existing)", add **provenance**
  (`applied_pack_id` on `coach_exercise_media`, set when a pack is applied). The
  overlay still owns its cues (editable independently); provenance only enables
  the bulk-update convenience. Design-system semantics for coaching.
- **Coach Knowledge Library** (post-beta) — let a coach organize everything they
  teach in one place: Packs · Voice Notes · Videos · Favorite Exercises ·
  Programming Rules · Warm-ups · Mobility Sequences · Coaching/Review Templates.
  A coach isn't just building workouts — they're building their coaching system
  on the platform. High retention: their accumulated expertise lives here.

## Recommendation

Keep it as the **#1 Phase-2 feature candidate.** It aligns with the platform's
identity better than almost anything else on the list, and the resolution
foundation already exists. Build **Phase 1 (L2)** either the moment a beta coach
asks for it, or as a deliberate pre-beta identity bet — not speculatively, and
not the giant generic library.
