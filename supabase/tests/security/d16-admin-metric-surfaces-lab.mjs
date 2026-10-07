// D16 · THE AUTHORIZED METRIC SURFACES — migrations 171/172, live against QA.
//
// WHY EVERY ASSERTION HERE IS A DELTA. An aggregate view is the easiest thing in
// this repository to test vacuously: `SELECT count(*)` over an empty table answers
// 0, HTTP 200, and a test that merely asserts "the admin got a row" passes whether
// or not the metric counts the right thing. Worse, four of these five metrics sit on
// populations that are EMPTY or near-empty on QA — checked_in_at on 0 of 2
// registrations, date_of_birth on 0 of 640 profiles, payments at 1 row. So this
// suite INSERTS a known fixture, re-reads, and asserts the specific column MOVED BY
// THE EXPECTED AMOUNT. A metric that counts nothing cannot pass.
//
// WHY THE BOUNDARY CASES ARE THE POINT FOR METRIC-17. The approved design's bucket
// labels overlap (30 and 45 each appear twice), so the only defect that matters is
// an age landing in two buckets or none. Ages 29/30/44/45/59/60 are each placed
// exactly once, and the totals are asserted to reconcile to users_total.
//
// WHY METRIC-02 IS TESTED AS AN AUTHORIZATION SPLIT. Option 3 reports a Session
// basis and a sign-in basis. The sign-in basis reads audit_events, which ruling B-1
// placed in the Security area. If the card leaked that figure to a Users-only role
// it would be an indirect read of the audit population. `support` holds Users·view
// and NOT Security·view in the approved matrix, so that role is the test.
import { IDENT, signIn, rest, mutate, svc, check, checkNoWrite,
         section, summary, beginSuite, n } from './lib.mjs';

const ONE = (b) => (Array.isArray(b) ? b[0] : b) || {};
const num = (v) => (v === null || v === undefined ? null : Number(v));

async function uidOf(key) {
  const r = await svc(`user_profiles?email=eq.${encodeURIComponent(IDENT[key].email)}&select=id`);
  return ONE(r.body).id;
}
async function assign(uid, role) {
  await svc(`admin_role_assignments?user_id=eq.${uid}`, { method: 'DELETE' });
  const r = await svc('admin_role_assignments', { method: 'POST', body: { user_id: uid, admin_role: role } });
  return r.status < 300;
}
async function unassign(uid) { if (uid) await svc(`admin_role_assignments?user_id=eq.${uid}`, { method: 'DELETE' }); }

// Read a metric view AS the signed-in caller, not as service: service bypasses RLS
// and admin_can() is false for it, so a service read proves nothing about access.
async function view(who, name) {
  const r = await rest(who, `${name}?select=*`);
  return { status: r.status, rows: n(r.body), row: ONE(r.body) };
}

async function run() {
  beginSuite();
  const victim = await signIn('victim');
  const vUid = await uidOf('victim');
  let created = { ws: [], reg: [], pay: [], fx: [], pod: [] };

  // Fixtures are deleted by MARKER first, so a crashed earlier run cannot leave rows
  // that make a correct delta assertion fail forever. Two such defects reached this
  // repository already (V5 §161).
  const purge = async () => {
    await svc(`workout_sessions?workout_title=eq.QA-D16-SESSION`, { method: 'DELETE' });
    await svc(`event_registrations?qr_code=like.QA-D16*`, { method: 'DELETE' });
    await svc(`payments?stripe_payment_intent_id=like.QA-D16*`, { method: 'DELETE' });
    await svc(`fx_rates?source=eq.QA-D16-FIXTURE`, { method: 'DELETE' });
    await svc(`accountability_pods?name=eq.QA-D16-POD`, { method: 'DELETE' });
    await svc(`coach_client_relationships?request_message=eq.QA-D16-CCR`, { method: 'DELETE' });
  };

  try {
    await purge();
    await assign(vUid, 'viewer');     // viewer holds Users, Security, Community, Events, Monetization · view

    // ── 1 · the gate, before any metric is trusted ─────────────────────────
    section('gates · an unassigned caller gets no row at all');
    await unassign(vUid);
    for (const v of ['admin_activity_overview', 'admin_user_overview',
                     'admin_events_overview', 'admin_community_overview',
                     'admin_revenue_overview']) {
      const r = await view(victim, v);
      check(`${v} yields ZERO rows to an unassigned caller`, r.rows === 0,
        `status=${r.status} rows=${r.rows}`);
    }
    await assign(vUid, 'viewer');
    for (const v of ['admin_activity_overview', 'admin_user_overview',
                     'admin_events_overview', 'admin_community_overview',
                     'admin_revenue_overview']) {
      const r = await view(victim, v);
      check(`${v} answers a Viewer`, r.rows === 1, `status=${r.status} rows=${r.rows}`);
    }

    // ── 2 · METRIC-02 · the two bases, and the authorization split ─────────
    section('METRIC-02 · Session and sign-in, separately gated');
    const before02 = (await view(victim, 'admin_activity_overview')).row;
    const wsIns = await svc('workout_sessions', { method: 'POST', body: {
      user_id: vUid, workout_title: 'QA-D16-SESSION', started_at: new Date().toISOString(),
      status: 'in_progress' } });
    check('arranged: a Session exists for today', wsIns.status < 300, `status=${wsIns.status}`);
    const after02 = (await view(victim, 'admin_activity_overview')).row;
    for (const col of ['session_users_today', 'session_users_week', 'session_users_month']) {
      check(`METRIC-02 ${col} COUNTS a Session inserted today`,
        num(after02[col]) === num(before02[col]) + 1,
        `${before02[col]} -> ${after02[col]}`);
    }
    check('METRIC-02 session_users_prev_month is NOT moved by a session dated today',
      num(after02.session_users_prev_month) === num(before02.session_users_prev_month),
      `${before02.session_users_prev_month} -> ${after02.session_users_prev_month}`);

    // THE SPLIT. support = Users·view yes, Security·view no.
    await assign(vUid, 'support');
    const sup = (await view(victim, 'admin_activity_overview')).row;
    check('METRIC-02 · support (Users, no Security) SEES the Session basis',
      num(sup.session_users_today) !== null, `session_users_today=${sup.session_users_today}`);
    check('METRIC-02 · support is given NULL — not 0 — for the sign-in basis, so the ' +
          'card cannot be read as "nobody signed in"',
      sup.signin_users_today === null && sup.signin_users_month === null,
      `today=${JSON.stringify(sup.signin_users_today)} month=${JSON.stringify(sup.signin_users_month)}`);
    await assign(vUid, 'viewer');
    const vw = (await view(victim, 'admin_activity_overview')).row;
    check('METRIC-02 · a Security-holding role DOES see the sign-in basis',
      num(vw.signin_users_today) !== null && num(vw.signin_users_month) !== null,
      `today=${vw.signin_users_today} month=${vw.signin_users_month}`);
    check('METRIC-02 · the sign-in basis is non-vacuous (audit_events holds ' +
          'authentication rows this month)', num(vw.signin_users_month) >= 1,
      `signin_users_month=${vw.signin_users_month}`);

    // ── 3 · METRIC-17 · half-open buckets, placed once each ────────────────
    section('METRIC-17 · the overlapping labels resolved to half-open intervals');
    const origAge = ONE((await svc(`user_profiles?id=eq.${vUid}&select=age,date_of_birth`)).body);
    const bucketFor = async (age) => {
      await svc(`user_profiles?id=eq.${vUid}`, { method: 'PATCH', body: { age, date_of_birth: null } });
      const r = (await view(victim, 'admin_user_overview')).row;
      return r;
    };
    const base = await (async () => {
      await svc(`user_profiles?id=eq.${vUid}`, { method: 'PATCH', body: { age: null, date_of_birth: null } });
      return (await view(victim, 'admin_user_overview')).row;
    })();
    const EDGES = [[29, 'age_18_30'], [30, 'age_30_45'], [44, 'age_30_45'],
                   [45, 'age_45_60'], [59, 'age_45_60'], [60, 'age_out_of_range'],
                   [17, 'age_out_of_range']];
    for (const [age, expected] of EDGES) {
      const r = await bucketFor(age);
      const moved = ['age_18_30', 'age_30_45', 'age_45_60', 'age_unknown', 'age_out_of_range']
        .filter((c) => num(r[c]) > num(base[c]));
      check(`METRIC-17 · age ${age} lands in ${expected} and NOWHERE else`,
        moved.length === 1 && moved[0] === expected, `moved=[${moved.join(',')}]`);
      const sum = ['age_18_30', 'age_30_45', 'age_45_60', 'age_unknown', 'age_out_of_range']
        .reduce((a, c) => a + num(r[c]), 0);
      check(`METRIC-17 · at age ${age} the buckets reconcile to users_total ` +
            '(nobody is silently dropped)', sum === num(r.users_total),
        `sum=${sum} users_total=${r.users_total}`);
    }
    // date_of_birth must WIN over the age fallback, or an edited age could override
    // the authoritative column.
    const dob = new Date(); dob.setFullYear(dob.getFullYear() - 35);
    await svc(`user_profiles?id=eq.${vUid}`, { method: 'PATCH',
      body: { age: 20, date_of_birth: dob.toISOString().slice(0, 10) } });
    const pref = (await view(victim, 'admin_user_overview')).row;
    check('METRIC-17 · date_of_birth (35) is preferred over the age column (20)',
      num(pref.age_30_45) === num(base.age_30_45) + 1 && num(pref.age_18_30) === num(base.age_18_30),
      `30_45 ${base.age_30_45}->${pref.age_30_45}, 18_30 ${base.age_18_30}->${pref.age_18_30}`);
    await svc(`user_profiles?id=eq.${vUid}`, { method: 'PATCH',
      body: { age: origAge.age ?? null, date_of_birth: origAge.date_of_birth ?? null } });

    // ── 4 · METRIC-03 · active coaches on a calendar month ────────────────
    section('METRIC-03 · calendar month');
    const u0 = (await view(victim, 'admin_user_overview')).row;
    check('METRIC-03 · active + no-client partition the coach population exactly',
      num(u0.coaches_active_this_month) + num(u0.coaches_no_client_this_month) === num(u0.coaches_total),
      `${u0.coaches_active_this_month} + ${u0.coaches_no_client_this_month} = ${u0.coaches_total}`);
    // NON-VACUITY IS ARRANGED, NOT ASSUMED. The obvious shortcut — "QA holds 118
    // active relationships so the figure cannot be 0" — is FALSE, and measuring it
    // proved so: of the 118 distinct coach_ids on active rows only ONE belongs to a
    // profile with role='coach' (59 of the first 60 are `trust_operator`). The live
    // figure of 1 is therefore CORRECT and the inference was wrong. So the metric is
    // proved by inserting a relationship for a real coach and watching it move.
    const coachUid = await uidOf('coach');
    const ccr = await svc('coach_client_relationships', { method: 'POST', body: {
      coach_id: coachUid, client_id: await uidOf('attacker'), status: 'active',
      initiated_by: coachUid, request_message: 'QA-D16-CCR' } });
    check('arranged: a real coach holds an active client relationship', ccr.status < 300,
      `status=${ccr.status}`);
    const u1 = (await view(victim, 'admin_user_overview')).row;
    const coachWasActive = num(u1.coaches_active_this_month) === num(u0.coaches_active_this_month);
    check('METRIC-03 · an active relationship makes its coach count as active this month',
      num(u1.coaches_active_this_month) >= num(u0.coaches_active_this_month) &&
      (coachWasActive || num(u1.coaches_active_this_month) === num(u0.coaches_active_this_month) + 1),
      `${u0.coaches_active_this_month} -> ${u1.coaches_active_this_month}` +
      (coachWasActive ? ' (p1-coach already held one)' : ''));
    check('METRIC-03 · the partition still holds exactly after the insert',
      num(u1.coaches_active_this_month) + num(u1.coaches_no_client_this_month) === num(u1.coaches_total),
      `${u1.coaches_active_this_month} + ${u1.coaches_no_client_this_month} = ${u1.coaches_total}`);
    check('METRIC-03 · the active figure is non-vacuous',
      num(u1.coaches_active_this_month) >= 1,
      `coaches_active_this_month=${u1.coaches_active_this_month}`);

    // ── 5 · METRIC-13 · a pod is an accountability_pods row ───────────────
    section('METRIC-13 · pods');
    const c0 = (await view(victim, 'admin_community_overview')).row;
    const podIns = await svc('accountability_pods', { method: 'POST', body: {
      coach_id: vUid, name: 'QA-D16-POD', max_members: 5, status: 'active' } });
    check('arranged: a pod exists', podIns.status < 300, `status=${podIns.status}`);
    const c1 = (await view(victim, 'admin_community_overview')).row;
    check('METRIC-13 · pods_total counts an accountability_pods row',
      num(c1.pods_total) === num(c0.pods_total) + 1, `${c0.pods_total} -> ${c1.pods_total}`);
    check('METRIC-13 · community_groups_total is NOT merged into the pod count',
      num(c1.community_groups_total) === num(c0.community_groups_total),
      `${c0.community_groups_total} -> ${c1.community_groups_total}`);

    // ── 6 · METRIC-14 · attended / registered, on the EXISTING column ─────
    section('METRIC-14 · attendance uses checked_in_at, which already exists');
    // TWO events, not two registrations on one: event_registrations carries
    // UNIQUE(event_id, user_id) (122:288), so the first draft's second insert
    // returned 409 and the metric assertions failed on MY fixture, not the view.
    const evs = (await svc('events?select=id&limit=2')).body;
    check('arranged: QA holds the two events this fixture needs', n(evs) === 2,
      `events available=${n(evs)}`);
    const e0 = (await view(victim, 'admin_events_overview')).row;
    const r1 = await svc('event_registrations', { method: 'POST', body: {
      event_id: evs[0].id, user_id: vUid, qr_code: 'QA-D16-A', status: 'registered' } });
    const r2 = await svc('event_registrations', { method: 'POST', body: {
      event_id: evs[1].id, user_id: vUid, qr_code: 'QA-D16-B', status: 'checked_in',
      checked_in_at: new Date().toISOString() } });
    check('arranged: one registration attended, one not', r1.status < 300 && r2.status < 300,
      `${r1.status}/${r2.status}`);
    const e1 = (await view(victim, 'admin_events_overview')).row;
    check('METRIC-14 · registrations_total counts both',
      num(e1.event_registrations_total) === num(e0.event_registrations_total) + 2,
      `${e0.event_registrations_total} -> ${e1.event_registrations_total}`);
    check('METRIC-14 · attended counts ONLY the one with checked_in_at',
      num(e1.event_registrations_attended) === num(e0.event_registrations_attended) + 1,
      `${e0.event_registrations_attended} -> ${e1.event_registrations_attended}`);
    const expectRate = Math.round(num(e1.event_registrations_attended) * 1000
      / num(e1.event_registrations_total)) / 10;
    check('METRIC-14 · the rate is attended / registered, not registrations / capacity',
      Math.abs(num(e1.event_attendance_rate_pct) - expectRate) < 0.11,
      `view=${e1.event_attendance_rate_pct} expected=${expectRate}`);
    check('METRIC-14 · the 30-day window counts a registration made now',
      num(e1.event_registrations_30d) >= 2, `30d=${e1.event_registrations_30d}`);

    // ── 7 · METRIC-06a/06b · the owner's calculation, and no fabrication ──
    section("METRIC-06 · gross / commission / net, and what the view REFUSES to invent");
    const p0 = (await view(victim, 'admin_revenue_overview')).row;
    const payIns = await svc('payments', { method: 'POST', body: {
      user_id: vUid, kind: 'coach', amount_cents: 5000, currency: 'usd', status: 'paid',
      commission_rate: 0.10, stripe_payment_intent_id: 'QA-D16-RATED' } });
    check('arranged: a coaching payment with a recorded rate', payIns.status < 300, `status=${payIns.status}`);
    const p1 = (await view(victim, 'admin_revenue_overview')).row;
    check('METRIC-06b · gross = sum of qualifying coaching amounts at source',
      num(p1.gross_coaching_cents) === num(p0.gross_coaching_cents) + 5000,
      `${p0.gross_coaching_cents} -> ${p1.gross_coaching_cents}`);
    check('METRIC-06b · commission = amount x the rate as it applied (5000 x 0.10 = 500)',
      num(p1.platform_commission_cents) === num(p0.platform_commission_cents) + 500,
      `${p0.platform_commission_cents} -> ${p1.platform_commission_cents}`);
    check('METRIC-06b · net = gross - commission, arithmetically consistent in the row',
      num(p1.net_platform_cents) === num(p1.gross_coaching_cents) - num(p1.platform_commission_cents),
      `${p1.gross_coaching_cents} - ${p1.platform_commission_cents} = ${p1.net_platform_cents}`);

    // NO FABRICATION. A payment with no recorded rate must raise the MISSING count
    // and must NOT be given a substituted rate.
    const unrated = await svc('payments', { method: 'POST', body: {
      user_id: vUid, kind: 'coach', amount_cents: 7000, currency: 'usd', status: 'paid',
      stripe_payment_intent_id: 'QA-D16-UNRATED' } });
    check('arranged: a coaching payment with NO recorded rate', unrated.status < 300, `status=${unrated.status}`);
    const p2 = (await view(victim, 'admin_revenue_overview')).row;
    check('METRIC-06b · gross includes the unrated payment',
      num(p2.gross_coaching_cents) === num(p1.gross_coaching_cents) + 7000,
      `${p1.gross_coaching_cents} -> ${p2.gross_coaching_cents}`);
    check('METRIC-06b · commission does NOT move for a payment with no recorded rate ' +
          '(no rate is substituted onto it)',
      num(p2.platform_commission_cents) === num(p1.platform_commission_cents),
      `${p1.platform_commission_cents} -> ${p2.platform_commission_cents}`);
    check('METRIC-06b · the gap is DISCLOSED: commission_rate_missing increments',
      num(p2.commission_rate_missing) === num(p1.commission_rate_missing) + 1,
      `${p1.commission_rate_missing} -> ${p2.commission_rate_missing}`);

    // EXCLUSION, asserted rather than assumed.
    const ticket = await svc('payments', { method: 'POST', body: {
      user_id: vUid, kind: 'event_ticket', amount_cents: 9900, currency: 'usd', status: 'paid',
      stripe_payment_intent_id: 'QA-D16-TICKET' } });
    const coachPlan = await svc('payments', { method: 'POST', body: {
      user_id: vUid, kind: 'coach_plan', amount_cents: 4900, currency: 'usd', status: 'paid',
      stripe_payment_intent_id: 'QA-D16-PLAN' } });
    check('arranged: a ticket and a coach_plan payment', ticket.status < 300 && coachPlan.status < 300,
      `${ticket.status}/${coachPlan.status}`);
    const p3 = (await view(victim, 'admin_revenue_overview')).row;
    check('METRIC-06b · event_ticket and coach_plan are EXCLUDED from coaching gross',
      num(p3.gross_coaching_cents) === num(p2.gross_coaching_cents),
      `${p2.gross_coaching_cents} -> ${p3.gross_coaching_cents}`);
    check('METRIC-06b · the exclusion is VISIBLE: excluded_non_coaching increments by 2',
      num(p3.excluded_non_coaching) === num(p2.excluded_non_coaching) + 2,
      `${p2.excluded_non_coaching} -> ${p3.excluded_non_coaching}`);
    // An unpaid coaching payment is not revenue.
    await svc('payments', { method: 'POST', body: {
      user_id: vUid, kind: 'coach', amount_cents: 11100, currency: 'usd', status: 'pending',
      commission_rate: 0.10, stripe_payment_intent_id: 'QA-D16-PENDING' } });
    const p4 = (await view(victim, 'admin_revenue_overview')).row;
    check('METRIC-06b · a PENDING coaching payment is not counted as revenue',
      num(p4.gross_coaching_cents) === num(p3.gross_coaching_cents),
      `${p3.gross_coaching_cents} -> ${p4.gross_coaching_cents}`);

    // METRIC-06a · FX is RECORDED, never assumed. NULL until a rate exists.
    check('METRIC-06a · with no usd->gbp rate recorded, the FX columns are NULL — the ' +
          'view does not invent a conversion',
      p4.fx_usd_gbp_rate === null && p4.fx_as_of === null && p4.fx_source === null,
      `rate=${JSON.stringify(p4.fx_usd_gbp_rate)} as_of=${JSON.stringify(p4.fx_as_of)}`);
    const fxIns = await svc('fx_rates', { method: 'POST', body: {
      base: 'usd', quote: 'gbp', rate: 0.79, as_of: new Date().toISOString().slice(0, 10),
      source: 'QA-D16-FIXTURE' } });
    check('arranged: an FX rate is recorded', fxIns.status < 300, `status=${fxIns.status}`);
    const p5 = (await view(victim, 'admin_revenue_overview')).row;
    check('METRIC-06a · the recorded rate, its date AND its source all reach the surface',
      Number(p5.fx_usd_gbp_rate) === 0.79 && p5.fx_as_of !== null && p5.fx_source === 'QA-D16-FIXTURE',
      `rate=${p5.fx_usd_gbp_rate} as_of=${p5.fx_as_of} source=${p5.fx_source}`);
    check('METRIC-06a · source_currency is declared, so no figure is currency-ambiguous',
      p5.source_currency === 'usd', `source_currency=${p5.source_currency}`);

    // ── 8 · the 158 lesson · a read surface must refuse mutation ──────────
    section('fx_rates · a read-only record cannot be written through PostgREST');
    const fxBefore = (await svc('fx_rates?select=id', { headers: { Prefer: 'count=exact' } }));
    const wIns = await mutate(victim, 'fx_rates', 'POST', {
      base: 'usd', quote: 'eur', rate: 1.0, as_of: '2026-01-01', source: 'QA-D16-FORBIDDEN' });
    const fxAfterIns = (await svc('fx_rates?select=id', { headers: { Prefer: 'count=exact' } }));
    checkNoWrite('an admin-layer caller CANNOT insert an FX rate', {
      before: n(fxBefore.body), after: n(fxAfterIns.body), status: wIns.status,
      detail: 'an FX rate the Admin layer could set is a revenue figure it could set' });
    const wPatch = await mutate(victim, `fx_rates?source=eq.QA-D16-FIXTURE`, 'PATCH', { rate: 99 });
    const stillOk = ONE((await svc('fx_rates?source=eq.QA-D16-FIXTURE&select=rate')).body);
    check('an admin-layer caller CANNOT alter a recorded FX rate (checked by re-reading ' +
          'the row, not by the PATCH status — PostgREST answers 204 either way)',
      Number(stillOk.rate) === 0.79, `status=${wPatch.status} rate still ${stillOk.rate}`);
    const wDel = await mutate(victim, `fx_rates?source=eq.QA-D16-FIXTURE`, 'DELETE', null);
    const survives = (await svc('fx_rates?source=eq.QA-D16-FIXTURE&select=id')).body;
    check('an admin-layer caller CANNOT delete a recorded FX rate',
      n(survives) === 1, `status=${wDel.status} rows surviving=${n(survives)}`);

    // ── 9 · no metric view discloses an individual ────────────────────────
    section('disclosure · the aggregates carry no identifier');
    for (const v of ['admin_activity_overview', 'admin_user_overview',
                     'admin_events_overview', 'admin_community_overview',
                     'admin_revenue_overview']) {
      const row = (await view(victim, v)).row;
      const leaks = Object.entries(row).filter(([k, val]) =>
        typeof val === 'string' &&
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(val));
      const emails = Object.entries(row).filter(([, val]) =>
        typeof val === 'string' && val.includes('@'));
      check(`${v} exposes no uuid and no email`,
        leaks.length === 0 && emails.length === 0,
        `uuid=[${leaks.map((x) => x[0])}] email=[${emails.map((x) => x[0])}]`);
    }
  } finally {
    await purge();
    await unassign(vUid);
  }
  return summary('D16 · authorized metric surfaces');
}

// THE RUNNER CONTRACT, which the first draft of this file got wrong: every suite
// here runs AT IMPORT and its default export is the FAILURE COUNT, not a function
// and not a boolean. Exporting the function meant run.mjs imported D16 without ever
// executing it and scored the result NaN/0 — a suite that silently did not run,
// which is the most dangerous way for a security test to "pass".
export default await run();
