// Runs every live security regression suite in order and exits non-zero if any
// assertion fails. Each suite default-exports its failure count.
//
//   export QA_URL=... QA_ANON=... QA_SERVICE=...
//   node supabase/tests/security/run.mjs
//
// The suites share fixtures and run sequentially on purpose — they arrange and
// tear down the same four identities and the same relationship rows.
import { results } from './lib.mjs';

const SUITES = [
  ['D-01  coach_client_relationships', './d01-coach-client-relationships.mjs'],
  ['D-02  role escalation / PAR-Q',    './d02-role-escalation.mjs'],
  ['D-03  weekly_checkins',            './d03-weekly-checkins.mjs'],
  ['1D    RPC execution security',     './d04-rpc-execution.mjs'],
  ['1E    intelligence substrate',     './d05-intelligence-substrate.mjs'],
  ['1F    sweep posture',              './d06-sweep-posture.mjs'],
];

let totalFailures = 0;
const summary = [];

for (const [label, path] of SUITES) {
  console.log(`\n${'█'.repeat(74)}\n██  ${label}\n${'█'.repeat(74)}`);
  const before = results.length;
  let failures;
  try {
    failures = (await import(path)).default ?? 0;
  } catch (err) {
    console.error(`  SUITE ERROR: ${err.message}`);
    failures = 1;
  }
  const ran = results.length - before;
  totalFailures += failures;
  summary.push({ label, ran, failures });
}

console.log(`\n${'█'.repeat(74)}\n██  PHASE 1 SECURITY REGRESSION SUMMARY\n${'█'.repeat(74)}`);
for (const s of summary) {
  console.log(`  ${s.failures === 0 ? 'PASS' : 'FAIL'}  ${s.label.padEnd(36)} ${String(s.ran - s.failures).padStart(3)}/${String(s.ran).padEnd(3)}`);
}
const total = summary.reduce((a, s) => a + s.ran, 0);
console.log(`\n  ${total - totalFailures}/${total} assertions passed across ${SUITES.length} suites`);
process.exit(totalFailures ? 1 : 0);
