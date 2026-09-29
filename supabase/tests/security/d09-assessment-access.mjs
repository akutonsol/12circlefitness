// N-07 — assessment access is coach-of-record only, and every read is logged.
//
// ── WHY ─────────────────────────────────────────────────────────────────────
// Intake writes 32 columns onto `user_profiles`, including parq_answers,
// risk_level, risk_score, medical_conditions, has_injuries, injury_locations,
// injury_description and food_allergies. Migration 102's SELECT policy grants
// the WHOLE ROW to:
//
//     id = auth.uid()
//     OR public.is_active_coach_of(id)
//     OR public.is_team_lead_of(id)     -- a team ROSTER
//     OR public.hosts_event_for(id)     -- an attendee LIST
//
// 102's own header shows the last two were added so a head coach could see a
// roster and a vendor an attendee list — that is, for NAMES. They carry the
// medical columns with them regardless. N-07's copy, "Only you and Amara can
// see this", is therefore false on the base-table path.
//
// get_client_assessment() is the narrow path: active coach ONLY, and it writes
// an audit row before it returns. This suite asserts that, and asserts the
// base-table exposure separately so the residual finding stays visible rather
// than being masked by the new RPC.
//
// ── STATUS ──────────────────────────────────────────────────────────────────
// Every assertion below requires the proposed migration in
// docs/proposed/N07_assessment_access.sql, which is authored and NOT applied —
// `docs/MASTER_REMEDIATION_WAVES.md` §0.2 assigns migration numbers 132+ at
// wave entry, never before. Until it is numbered, applied and registered in
// run.mjs, this suite fails by design. That is the pre-fix reading, not a
// defect — the same convention d08 records for migration 131. Do not delete it
// to make the runner green.
import { URL_, rest, rpc, svc, mutate, blocked, signIn,
         check, section, summary, n, loadIds } from './lib.mjs';

// POSITIVE allowlist, matching d07/d08/d10/d11. `lib.mjs` only BLOCKS the
// production ref, and "is not production" is not "is QA" — a third project
// would sail straight through.
//
// This suite needs the guard more than any other in the directory, because its
// arrange step issues service_role DELETEs against `coach_client_relationships`
// and `assessment_access_log` filtered only by client_id. Pointed at the wrong
// project that is destructive, not merely wrong.
const QA_REF = 'eyqtldjqpgpljlqvpowh';
if (!URL_.includes(QA_REF)) {
  console.error(`REFUSING TO RUN: "${URL_}" is not the 12 Circle QA project (${QA_REF}).`);
  process.exit(2);
}

// ── BEFORE THIS SUITE MAY BE REGISTERED IN run.mjs ──────────────────────────
// Two things must be true, and neither is today:
//
//   1. N-07's migration must be numbered, applied and its objects present.
//      `get_client_assessment()` and `assessment_access_log` do NOT exist —
//      zero references in supabase/migrations, zero in the live QA catalog —
//      so all seven RPC assertions below would fail on a missing function
//      rather than on a boundary. N-07 is blocked on owner decision OD-30
//      ("coach access to PAR-Q"), so there is no date for this.
//
//   2. The arrange step must stop mutating SHARED fixture state. `reset()`
//      DELETEs every coach_client_relationships row for the victim — the same
//      fixture d01 asserts on. That is the cross-suite contamination class that
//      made a d11 assertion vacuous in V5 §33.4, and it must be fixed before
//      this suite runs alongside the others, not after.
//
// Until both hold, this file is committed but NOT registered: it is preserved
// evidence, not part of the green suite. Registering it today would add no
// coverage of anything that exists and would make CI permanently red.
// ─────────────────────────────────────────────────────────────────────────────

const REL  = 'coach_client_relationships';
const LOG  = 'assessment_access_log';
const MED  = 'parq_answers,risk_level,risk_score,medical_conditions,has_injuries,' +
             'injury_locations,injury_description,food_allergies';
const ids  = await loadIds();

// Arrange: coach is coach-of-record for victim; attacker is a client with no
// relationship to victim at all.
const reset = async () => {
  await svc(`${REL}?client_id=eq.${ids.victim}`, { method: 'DELETE' });
  await svc(`${LOG}?client_id=eq.${ids.victim}`, { method: 'DELETE' });
};
await reset();
await svc(REL, { method: 'POST', body: JSON.stringify(
  { coach_id: ids.coach, client_id: ids.victim, status: 'active', initiated_by: 'coach' }) });

await signIn('coach'); await signIn('attacker'); await signIn('victim'); await signIn('admin');

// ═══ 1. the assigned coach ═════════════════════════════════════════════════
section('1. Assigned coach can read the assessment (QA-1)');
{
  const r = await rpc('coach', 'get_client_assessment', { p_client: ids.victim });
  check('assigned coach receives the assessment', r.status < 300 && n(r.body) === 1,
        `status=${r.status} rows=${n(r.body)}`);
  const row = Array.isArray(r.body) ? r.body[0] : r.body;
  check('assessment carries the safety-critical fields',
        !!row && 'parq_answers' in row && 'injury_description' in row && 'risk_level' in row,
        row ? Object.keys(row).length + ' cols' : 'no row');
}

// ═══ 2. an unassigned coach ════════════════════════════════════════════════
section('2. Unassigned callers are refused (QA-2)');
{
  const a = await rpc('attacker', 'get_client_assessment', { p_client: ids.victim });
  check('client with no relationship is refused', a.status >= 400, `status=${a.status}`);

  const an = await rpc('anon', 'get_client_assessment', { p_client: ids.victim });
  check('anon is refused', an.status >= 400, `status=${an.status}`);

  // Ending the relationship must revoke access immediately.
  await svc(`${REL}?client_id=eq.${ids.victim}`, { method: 'PATCH',
            body: JSON.stringify({ status: 'ended' }) });
  const after = await rpc('coach', 'get_client_assessment', { p_client: ids.victim });
  check('a coach whose relationship ended is refused', after.status >= 400, `status=${after.status}`);
  await svc(`${REL}?client_id=eq.${ids.victim}`, { method: 'PATCH',
            body: JSON.stringify({ status: 'active' }) });
}

// ═══ 3. the client's own access is unchanged ═══════════════════════════════
section("3. The client still reads their own record (QA-3)");
{
  const own = await rest('victim', `user_profiles?id=eq.${ids.victim}&select=${MED}`);
  check('client reads their own assessment fields', own.status < 300 && n(own.body) === 1,
        `status=${own.status} rows=${n(own.body)}`);
}

// ═══ 4. honest emptiness ═══════════════════════════════════════════════════
section('4. Missing assessment data is reported honestly (QA-4)');
{
  const r = await rpc('coach', 'get_client_assessment', { p_client: ids.victim });
  const row = Array.isArray(r.body) ? r.body[0] : r.body;
  check('has_assessment is present and boolean',
        !!row && typeof row.has_assessment === 'boolean', `value=${row && row.has_assessment}`);

  // A client the coach is assigned to but who has no profile row at all must
  // yield zero rows — "no assessment on file", never an empty-looking one.
  const ghost = '00000000-0000-0000-0000-0000000000ff';
  await svc(REL, { method: 'POST', body: JSON.stringify(
    { coach_id: ids.coach, client_id: ghost, status: 'active', initiated_by: 'coach' }) });
  const g = await rpc('coach', 'get_client_assessment', { p_client: ghost });
  check('absent profile returns no row rather than a blank assessment',
        g.status >= 400 || n(g.body) === 0, `status=${g.status} rows=${n(g.body)}`);
  await svc(`${REL}?client_id=eq.${ghost}`, { method: 'DELETE' });
}

// ═══ 5. no alternate route ═════════════════════════════════════════════════
section('5. No leak through an alternate route (QA-7)');
{
  const direct = await rest('attacker', `user_profiles?id=eq.${ids.victim}&select=${MED}`);
  check('unassigned client cannot read medical columns directly',
        direct.status >= 400 || n(direct.body) === 0,
        `status=${direct.status} rows=${n(direct.body)}`);

  const anon = await rest('anon', `user_profiles?id=eq.${ids.victim}&select=${MED}`);
  check('anon cannot read medical columns directly',
        anon.status >= 400 || n(anon.body) === 0, `status=${anon.status} rows=${n(anon.body)}`);

  // The view used for names must not carry clinical columns.
  const pv = await rest('attacker', `public_profiles?id=eq.${ids.victim}&select=*`);
  const leaked = Array.isArray(pv.body) && pv.body[0]
    ? Object.keys(pv.body[0]).filter(k => MED.split(',').includes(k)) : [];
  check('public_profiles projects no clinical column', leaked.length === 0, leaked.join(',') || 'none');
}

// ═══ 6. the audit row ══════════════════════════════════════════════════════
section('6. Access is actually logged, and the log is honest (QA-8)');
{
  await svc(`${LOG}?client_id=eq.${ids.victim}`, { method: 'DELETE' });
  await rpc('coach', 'get_client_assessment', { p_client: ids.victim });

  const rows = await svc(`${LOG}?client_id=eq.${ids.victim}&select=coach_id,client_id,event,accessed_at`);
  const row  = Array.isArray(rows.body) ? rows.body[0] : null;
  check('an audit row was persisted', n(rows.body) === 1, `rows=${n(rows.body)}`);
  check('the audit row names the coach, the client and the event',
        !!row && row.coach_id === ids.coach && row.client_id === ids.victim
              && row.event === 'assessment_view' && !!row.accessed_at,
        row ? JSON.stringify(row) : 'none');

  // The subject can inspect who opened their record — this is what makes the
  // on-screen privacy claim verifiable rather than merely asserted.
  const mine = await rest('victim', `${LOG}?select=coach_id,event,accessed_at`);
  check('the client can read their own access log', mine.status < 300 && n(mine.body) >= 1,
        `status=${mine.status} rows=${n(mine.body)}`);

  const other = await rest('attacker', `${LOG}?client_id=eq.${ids.victim}&select=coach_id`);
  check('a third party cannot read the log', other.status >= 400 || n(other.body) === 0,
        `status=${other.status} rows=${n(other.body)}`);

  // An audit trail a caller can edit or erase is not an audit trail.
  const upd = await mutate('coach', `${LOG}?client_id=eq.${ids.victim}`, 'PATCH',
                           { event: 'assessment_view' });
  check('nobody can UPDATE an audit row', blocked(upd), `status=${upd.status} affected=${upd.affected}`);
  const del = await mutate('coach', `${LOG}?client_id=eq.${ids.victim}`, 'DELETE');
  check('nobody can DELETE an audit row', blocked(del), `status=${del.status} affected=${del.affected}`);
}

// ═══ 7. the residual base-table exposure ═══════════════════════════════════
section('7. RESIDUAL FINDING — the base-table path is still wider than N-07');
{
  // Recorded as an assertion so the exposure cannot be quietly forgotten once
  // the narrow RPC exists. These are EXPECTED TO FAIL until the owner rules on
  // the base-table policy; the RPC does not fix them and never claimed to.
  const lead = await rest('admin', `user_profiles?id=eq.${ids.victim}&select=${MED}`);
  check('S-N07-a  a team lead cannot read a member\'s medical columns',
        lead.status >= 400 || n(lead.body) === 0,
        `status=${lead.status} rows=${n(lead.body)} — is_team_lead_of() grants the whole row`);
}

await reset();
export default summary('N-07 assessment access');
