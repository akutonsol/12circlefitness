# V5 autonomous run — 2026-10-07 — consolidated owner pack

**Second revision.** The first version of this pack carried twelve items. **Six are now
closed** — by existing authority, by measuring the published artifacts, or because I had
re-asked something already answered. They are listed in §0 so the same questions are not
rediscovered later.

Nothing below blocked the run. Each entry states what was built, so "no change needed" is
a valid answer.

---

## 0 · CLOSED since the first revision — do not re-ask

| was | why it is closed |
|---|---|
| **A2 · should `60+` be a real bucket?** | **Already answered, by you.** The directive that authorized METRIC-17 says: *"Do not invent a 60+ bucket. Any genuinely 60+ records … must remain in the appropriate reconciliation/unknown handling rather than being silently assigned to an invented category."* That is exactly `age_out_of_range`. **I re-asked a question you had answered in the same message that set the task.** |
| **A3 · where are METRIC-16/18/19 ledgered?** | Resolved by evidence. The non-operational register is keyed by `(area, verb)` **capability** and its validator cross-checks every row against the approved matrix; a Dashboard **card** cannot be expressed in it. The programme ledger is the only coherent home. |
| **B1 · which subject owns a multi-assignment program's feedback?** | Resolved by evidence (§175.2). `generate_client_plan` (`121:221`) inserts a fresh program then **exactly one** assignment, so a generated plan is 1:1 with its client by construction; and `weekly_feedback` is `unique (program_id, week)`, so a template assigned to N clients cannot have one row per week **whichever** subject were chosen. Not a model to choose — an incoherent state. Now a monitored invariant in D17. |
| **B2 · should an unknown coaching mode require approval?** | Resolved by **authority**, then fixed (§175.1, migration 177). `product-bible:111` forbids bypassing the matrix for coach-guided clients, `:116` forbids a claim it cannot ground, `decision-log:18` licenses auto-apply **only** for AI/self-guided, and `MASTER_PRODUCT_DECISIONS:63` says of this very function that silently disabling the matrix is *"a hard-constraint violation… **No decision needed**"*. |
| **C2 · the untokenised severity colour** | Resolved by measuring the package (§176). The approved screens hold **zero `var(--adm-*)` references and 447 literal hex values**; `admin.tokens.css` is **derived from** them and **normalises** — `#f07a8c` ×80 vs `#f08a9b` ×15, six danger-tint alphas collapsed to one, `11px` chosen over `11.5px` as a scale step. Reading from the tokens is **conformance**, not deviation. §168.2 corrected. |
| **A1 · METRIC-02's weekly window** | **Superseded, and I asked the wrong question.** The data contract (`:98`) names the sub-questions the definition must settle, and the week is not among them. See **Q1** and **Q2**, which are. |

---

## 1 · Open questions

**Q1 · In which timezone is "today" measured?** *(data contract `:98`, explicitly unsettled)*
METRIC-02 = Option 3 settled *which events count* and nothing else. The windows are
currently **UTC**, because that is the database's timezone. Migration 176 **publishes**
the boundaries rather than choosing — `day_start`, `week_start`, `month_start`,
`window_timezone` are columns, and the card renders *"Day begins 2026-10-07 00:00 UTC"*.
**Blocks:** nothing — the figures are correct and now self-describing. **Needed for:** a
DAU figure that matches how the business thinks about a day.

**Q2 · Does a coach or partner count as an "active user", or only clients?** *(same line)*
The counts are over **every** user with a Session, no role filter — as shipped. A filter
would be a business definition, so none was invented. **Blocks:** nothing.

**Q3 · Release the CI-ingestion path for METRIC-11?** Your ruling settled what the card
shows, and that is built. The **ingestion** path is a separate item the data contract
records at `:220` as `C · ARCHITECTURE`, citing `P10`'s *"installation forbidden"* and
`CONF-D9` — neither released. The registry starts empty and D16 asserts it is empty, so
nobody can seed it to make the dashboard look finished. **Blocks:** only live values on
that one card.

**Q4 · Merge the design branch, or keep commit-pinned citations?** `931218b` on
`design/12circle-plus-admin-dashboard` is **not an ancestor of this branch**. The token
layer is generated from it by `git show`, four documents carry a provenance block, and a
guard fails CI on any design citation that resolves nowhere. **Blocks:** nothing.

**Q5 · Add a Phosphor icon dependency?** The inventory names **107 icons** across the Admin
pages. My implemented surface uses **one**, substituted with a Material fill-weight
equivalent and labelled as a substitution. **Blocks:** nothing today; the cost grows with
the Admin build-out.

---

## 2 · New since the first revision

**N1 · A coach is now asked to approve an action the engine does not execute.**
A direct consequence of my own fix. `ENG-02`/`ENG-14` are remediated, so `evaluate_week`
now returns `needs_approval = true` for a coach-guided client — including for
`REPLACE_EXERCISES`. But `ENG-13` (P2, Wave 5, source-cited at `094:80-140`) records that
`regenerate_program` **implements only two of its own four actions**: it mutates
`volume_multiplier` and `is_deload`, and *"no exercise is ever substituted"*. So the
approval path is now live for a change that will not be applied. **This is strictly better
than the previous state** — the matrix was inert and changes auto-applied — but it is a
real seam, and it was not visible before the fix. **Decision:** prioritise `ENG-13`, or
accept the seam until Wave 5.

**N2 · `EC-03`'s end-to-end rung is not built.** `QA_CLOSURE_STANDARD` scores it in the
*"Error contract / false success"* class, which requires **VERIFIED END-TO-END** for a
user-facing state. `EC-04`'s rung now exists (a device probe reading the real accessibility
tree, new CI job `ec04-e2e`). EC-03's needs a driver that makes the save genuinely fail —
a harder fixture that touches onboarding. **Recorded as remaining frontier, not claimed.**

**N3 · INFRASTRUCTURE BLOCKER, local only.** `xcode-select -p` is
`/Library/Developer/CommandLineTools` and there is **no `Xcode.app`**, so `xcrun` cannot
find `xcodebuild` and the macOS desktop target cannot build on this machine. Installing
Xcode needs your machine and your password. **Blocks:** running device probes *locally*.
**Does not block:** CI, which has the Linux desktop target and runs them.

---

## 3 · Recorded debt — no decision needed unless you want it prioritised

| # | item |
|---|---|
| **D1** | Two legacy display coercions remain in `SEC-G4`'s shrinking allowlist — `observability_screen:62` and `admin_dashboard_screen:224` render a missing figure as `0` on the pre-token console. |
| **D2** | `_saveProgress` Phase 2 is still `catch (_) {}` — the progressive autosave, with `_finish()`'s full upsert as its backstop. |
| **D3** | **`MASTER_REMEDIATION_REGISTRY.md` is outside this run's mutation boundary and was not edited**, so `I-COM-01`, `EC-04`, `EC-03`, `ENG-02` and `ENG-14` still read `READY_TO_REMEDIATE`. `REMEDIATION_PROGRESS.md` cannot carry them either — it states *"This board never leads the registry."* Their evidence is §169–§177. |
| **D4** | `DESIGN-01` §2's `Guardian-approval-required` state remains unimplemented; that document deliberately stops short of specifying it. |
