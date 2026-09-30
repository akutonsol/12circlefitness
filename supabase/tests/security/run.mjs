// Runs every live security regression suite in order and exits non-zero if any
// assertion fails. Each suite default-exports its failure count.
//
//   export QA_URL=... QA_ANON=... QA_SERVICE=...
//   node supabase/tests/security/run.mjs
//
// The suites share fixtures and run sequentially on purpose — they arrange and
// tear down the same four identities and the same relationship rows.
import { results, beginSuite } from './lib.mjs';

const SUITES = [
  ['D-01  coach_client_relationships', './d01-coach-client-relationships.mjs'],
  ['D-02  role escalation / PAR-Q',    './d02-role-escalation.mjs'],
  ['D-03  weekly_checkins',            './d03-weekly-checkins.mjs'],
  ['1D    RPC execution security',     './d04-rpc-execution.mjs'],
  ['1E    intelligence substrate',     './d05-intelligence-substrate.mjs'],
  ['1F    sweep posture',              './d06-sweep-posture.mjs'],
  ['3A-10 chat-media storage',         './d07-chat-media-storage.mjs'],
  // 3A-11. CORRECTED 2026-09-30 (V5 §64). This comment used to read "migration
  // 131 is authored and NOT applied … this suite fails by design". That is no
  // longer true and had become the more dangerous of the two errors: it told a
  // reader that a 3A-11 FAILURE was EXPECTED, which would have masked a real
  // regression in the one instrument meant to catch them.
  //
  // Migration 131 IS applied. Verified against the live QA catalog, not source:
  // all six of its objects are present — the four unique indexes
  // (client_nutrition_plans_one_active_per_client, cycle_logs_one_period_per_start,
  // conversations_unique_participant_pair, client_session_credits_unique_payment)
  // and both functions (assign_nutrition_plan, get_or_create_conversation).
  // The suite passes 24/24 and a failure here is a REGRESSION, not the pre-fix
  // reading.
  ['3A-11 identity constraints',       './d08-identity-constraints.mjs'],
  // N-07. Registered under owner decision OD-56 = A, now that migration 140 is
  // applied and `get_client_assessment()` / `assessment_access_log` exist. It was
  // deliberately held OUT of this list while they did not (V5 §42): its seven RPC
  // assertions would have failed on a missing function rather than on a boundary.
  ['N-07  assessment access',          './d09-assessment-access.mjs'],
  // P1. The three surfaces migrations 135/136 changed. No other suite probed
  // any of them — verified by search before this one was written. It asserts
  // POST-FIX behaviour only; the pre-fix half of §5.2 is catalog-level and is
  // recorded in docs/V5_PROGRAMME_DEFINITION.md §23.2, because 135/136 were
  // already applied before a request-level probe existed.
  ['P1    profile + status boundaries', './d10-p1-profile-and-status-boundaries.mjs'],
  // BIL-3/K-04, pulled into P1 by owner Decision A. Unlike d10 this suite has
  // BOTH halves of §5.2 on QA and needed no rollback to get them: the defect
  // was live on QA and had never been remediated there, so the red half is a
  // real pre-138 run (2/8) recorded in §32.4. Registering it here is the
  // VERIFIED IN CI rung the Security/authorization class demands (§2.1); until
  // CI actually runs it, K-04 is REMEDIATED and not VERIFIED_CLOSED.
  ['K-04  event registration integrity', './d11-event-registration-integrity.mjs'],
  // P2 · the four D4/D12 populations, the A12 identity mapping, severance and the
  // A13 read path (migrations 142-152 -- this comment said "142-148" until V5 §94;
  // 149's observability writer-of-record, 150's A6 delta, 151's B1-B4 emitters and
  // 152's audit_read + severance events are all covered here too). Registered only
  // after it was executed against QA and shown non-vacuous: its first live run
  // FAILED one assertion (service_role INSERTed control evidence, 201) and its
  // second failed another for the right reason after 148 revoked a grant the suite
  // had been relying on. Both are recorded in V5 §80.
  //
  // COUNT CORRECTED, V5 §94. This comment read "It now passes 27/27" -- the 27 was
  // true at registration and was never updated as 149-152 added assertions. Measured
  // live on QA 2026-09-30 at the 152 frontier: 70/70. A stale pass count is the same
  // hazard class as the "3A-11 fails by design" comment above -- it tells a reader
  // what to expect, so it must be measured, not remembered.
  //
  // NOTE: this suite CANNOT clean up after itself. audit_events is append-only by
  // A11 and its freeze refuses DELETE to every caller including service_role, so
  // each run leaves permanent rows on QA. That is the population behaving as
  // ruled. Rows carry a run-unique marker so they stay attributable.
  ['P2    audit + observability populations', './d12-p2-audit-populations.mjs'],
];

let totalFailures = 0;
const summary = [];

for (const [label, path] of SUITES) {
  console.log(`\n${'█'.repeat(74)}\n██  ${label}\n${'█'.repeat(74)}`);
  beginSuite();
  const before = results.length;
  let failures;
  let aborted = false;
  try {
    failures = (await import(path)).default ?? 0;
  } catch (err) {
    console.error(`  SUITE ERROR: ${err.message}`);
    failures = 1;
    aborted = true;
  }
  const ran = results.length - before;
  totalFailures += failures;
  summary.push({ label, ran, failures, aborted });
}

console.log(`\n${'█'.repeat(74)}\n██  PHASE 1 SECURITY REGRESSION SUMMARY\n${'█'.repeat(74)}`);
// V5 §28.9. An ABORTED suite used to render IDENTICALLY to a failing one: the
// catch above scores a throw as failures=1, so a suite that died on a network
// error after 24 passing assertions printed "23/24" -- visually indistinguishable
// from one real regression, and "-1/0" when it died at assertion 0. During the
// connectivity degradation of §31 that misreading happened repeatedly, and in CI
// it would present a dropped connection as a security regression. The state is
// now named rather than inferred.
for (const s of summary) {
  const verdict = s.aborted ? 'ABORT' : s.failures === 0 ? 'PASS' : 'FAIL';
  const score = s.aborted
    ? `${String(s.ran).padStart(3)} ran, DID NOT FINISH`
    : `${String(s.ran - s.failures).padStart(3)}/${String(s.ran).padEnd(3)}`;
  console.log(`  ${verdict.padEnd(5)} ${s.label.padEnd(36)} ${score}`);
}
const total = summary.reduce((a, s) => a + s.ran, 0);
const abortedSuites = summary.filter(s => s.aborted);
const assertionFailures = totalFailures - abortedSuites.length;
console.log(`\n  ${total - assertionFailures}/${total} assertions passed across ${SUITES.length} suites`);
if (abortedSuites.length) {
  console.log(
    `\n  ⚠  ${abortedSuites.length} suite(s) ABORTED and did not finish: ` +
    `${abortedSuites.map(s => s.label.trim().split(/\s{2,}/)[0]).join(', ')}.` +
    `\n     An abort is an INCOMPLETE RUN, not a failed assertion. Assertion-level` +
    `\n     failures in this run: ${assertionFailures}. Re-run before reading the result` +
    `\n     as a regression -- see V5 §28.9 and §31.`
  );
}
process.exit(totalFailures ? 1 : 0);
