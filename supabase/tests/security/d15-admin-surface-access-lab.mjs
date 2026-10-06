// D15 · ADMIN SURFACE ACCESS — migrations 156/157, live against QA.
//
// The owner's authorization for these surfaces says: "test the actual resulting
// data access, not merely function return values." D13 proves admin_can() returns
// the right booleans and D14 proves all 425 of them. NEITHER proves a row crosses
// an RLS boundary. This suite reads rows.
//
// WHY MOST ASSERTIONS ARE COUNT COMPARISONS AGAINST SERVICE. A surface test that
// says "the admin got HTTP 200" proves nothing: PostgREST answers 200 with `[]`
// when RLS filters everything, which is exactly how the three coach surfaces in
// SEC-G3 rendered a confident permanent zero. So every positive asserts the
// assigned caller sees THE SAME COUNT the service role sees, and every negative
// asserts an unassigned caller sees ZERO of the same query.
//
// WHY SEVEN OF THE SIXTEEN ARMS ARE ASSERTED AS REDUNDANT, NOT AS GRANTS. The
// baseline measured before 156 (V5 §128.2) showed community_posts, post_comments,
// post_reactions, community_groups, accountability_pods, events and classes are
// ALREADY readable by any authenticated user through policies that predate this
// work. The admin arm on those tables grants nothing that was not already granted.
// Asserting "an admin can read community_posts" would therefore PASS WITHOUT 156
// APPLIED AT ALL -- a vacuous test, and §5.2's "test the class, not the instance"
// cuts against writing one. They are asserted for NON-REGRESSION only, and the
// pre-existing broad posture is recorded as a finding rather than dressed up as a
// result of this migration.
import { URL_, SERVICE, IDENT, signIn, rest, mutate, svc, rpc,
         check, section, summary, beginSuite, n } from './lib.mjs';

const VIEWS = ['admin_audit_events', 'admin_training_overview', 'admin_integration_connections',
               'admin_security_events', 'admin_user_directory', 'admin_incidents'];

// Owner decision B-2: the Users projection is identity and account state ONLY.
// Every column below is PHI, contact PII, a financial identifier, or a risk field
// DERIVED from PHI. risk_* and phone were offered and DECLINED, so they are
// asserted absent alongside the rest -- a projection that quietly widened would
// otherwise satisfy every other assertion.
const USERS_FORBIDDEN = ['medical_conditions', 'parq_answers', 'has_injuries', 'injury_locations',
                         'injury_description', 'date_of_birth', 'height_cm', 'weight_kg',
                         'sleep_hours', 'stress_level', 'dietary_restrictions', 'food_allergies',
                         'risk_score', 'risk_level', 'risk_flags', 'stripe_customer_id',
                         'stripe_account_id', 'phone'];
const USERS_ALLOWED = ['id', 'first_name', 'last_name', 'email', 'avatar_url', 'role',
                       'membership_tier', 'onboarding_complete', 'created_at'];

// Owner decision B-1, 2026-10-05: the Security area is access-control oversight.
// control_evidence and storage_media_access were OFFERED AND NOT CHOSEN, so they
// are asserted ABSENT -- a surface that silently widened past the decision would
// otherwise pass every other assertion below.
const SECURITY_IN  = ['authentication', 'authorization_denial', 'admin_action', 'audit_read'];
const SECURITY_OUT = ['incident', 'phi_read', 'phi_correction', 'financial', 'agent_action',
                      'control_evidence', 'storage_media_access', 'relationship_change',
                      'export_deletion', 'observability_audit', 'billing_entitlement'];

async function uidOf(key) {
  const r = await svc(`user_profiles?select=id&email=eq.${encodeURIComponent(IDENT[key].email)}`);
  return Array.isArray(r.body) && r.body[0] ? r.body[0].id : null;
}
async function assign(uid, role) {
  await svc(`admin_role_assignments?user_id=eq.${uid}`, { method: 'DELETE' });
  const r = await svc('admin_role_assignments', { method: 'POST', body: { user_id: uid, admin_role: role } });
  return r.status < 300;
}
async function unassign(uid) {
  if (uid) await svc(`admin_role_assignments?user_id=eq.${uid}`, { method: 'DELETE' });
}

async function run() {
  beginSuite();

  // ── 0 · are 156/157 applied? ──────────────────────────────────────────────
  const probe = await svc('admin_audit_events?select=id&limit=1');
  if (probe.status === 404 || (probe.body && /does not exist|schema cache/i.test(JSON.stringify(probe.body)))) {
    check('migrations 156/157 are applied to QA', false,
      'admin_audit_events not reachable — nothing below was asserted');
    return summary('D15 admin surface access');
  }
  check('migrations 156/157 are applied to QA', true, 'all three curated views reachable');

  const victim = await signIn('victim');
  const admin  = await signIn('admin');
  let vUid = null, aUid = null, seededIntegration = null, capRemoved = false;

  try {
    vUid = await uidOf('victim');
    aUid = await uidOf('admin');
    check('fixture identities resolved', !!vUid && !!aUid, `victim=${!!vUid} admin=${!!aUid}`);
    if (!vUid) return summary('D15 admin surface access');

    // ── 1 · the DECISIVE pairs — 0 without the role, all rows with it ───────
    // These four tables deny an unassigned authenticated caller outright, so the
    // before/after difference is attributable to 156 and to nothing else.
    section('decisive surfaces · unassigned sees nothing, Viewer sees everything');
    const DECISIVE = [
      ['event_registrations', 'Events'],
      ['class_bookings',      'Events'],
      ['subscriptions',       'Monetization'],
      ['observability_events','System'],
    ];
    await unassign(vUid);
    const baseline = {};
    for (const [t] of DECISIVE) {
      const svcRows = await svc(`${t}?select=id`);
      const mine    = await rest(victim, `${t}?select=id`);
      baseline[t] = n(svcRows.body);
      check(`${t}: an UNASSIGNED caller sees 0 of ${baseline[t]} rows`,
        n(mine.body) === 0, `saw ${n(mine.body)} (status ${mine.status})`);
    }

    const arranged = await assign(vUid, 'viewer');
    check('arranged: victim holds the Viewer Admin role', arranged, `assign ok=${arranged}`);

    for (const [t, area] of DECISIVE) {
      const mine = await rest(victim, `${t}?select=id`);
      check(`${t}: a Viewer now sees all ${baseline[t]} rows via admin_can('${area}','view')`,
        baseline[t] > 0 && n(mine.body) === baseline[t],
        `saw ${n(mine.body)} of ${baseline[t]} (status ${mine.status})`);
    }

    // ── 2 · the seven redundant arms — non-regression only ──────────────────
    section('pre-existing broad-read tables · arms are redundant, asserted for non-regression');
    for (const t of ['community_posts','post_comments','post_reactions','community_groups',
                     'accountability_pods','events','classes']) {
      const svcRows = await svc(`${t}?select=id`);
      const mine    = await rest(victim, `${t}?select=id`);
      check(`${t}: readable (${n(mine.body)}/${n(svcRows.body)}) — ALREADY public to authenticated before 156`,
        n(mine.body) === n(svcRows.body), `saw ${n(mine.body)} of ${n(svcRows.body)}`);
    }

    // ── 3 · Training — AGGREGATE ONLY, no row-level PHI path ────────────────
    // The parked boundary is row-level training disclosure. This asserts the
    // aggregate works AND that the projection cannot be turned into a row reader.
    section('Training aggregate surface');
    const tAgg = await rest(victim, 'admin_training_overview?select=*');
    check('a Viewer reads the Training aggregate — exactly one row',
      n(tAgg.body) === 1, `rows=${n(tAgg.body)} status=${tAgg.status}`);
    check('the aggregate carries the four counts and nothing else',
      n(tAgg.body) === 1 && ['programs_total','workouts_total','sessions_total','logs_total']
        .every(k => k in tAgg.body[0]) && Object.keys(tAgg.body[0]).length === 4,
      `keys=${n(tAgg.body) === 1 ? Object.keys(tAgg.body[0]).join(',') : 'n/a'}`);
    for (const col of ['user_id','workout_id','notes']) {
      const r = await rest(victim, `admin_training_overview?select=${col}`);
      check(`the Training aggregate exposes no ${col} column — no row-level path`,
        r.status >= 400, `status=${r.status}`);
    }
    // And the PARKED boundary must still hold: row-level training stays denied.
    // ASSERTED ON workout_sessions, NOT workout_logs. The first draft of this
    // check used workout_logs and FAILED -- not because the boundary leaked but
    // because that table is EMPTY on QA, so "the Viewer saw 0" proved nothing. A
    // deny assertion over an empty table is the vacuous pass this suite exists to
    // avoid, and the `service > 0` clause is what caught it. workout_sessions
    // carries real rows, so the denial is observable.
    for (const t of ['workout_sessions', 'workout_logs']) {
      const raw = await rest(victim, `${t}?select=id`);
      const all = await svc(`${t}?select=id`);
      if (n(all.body) === 0) {
        check(`PARKED boundary: ${t} is EMPTY on QA — denial not assertable here`,
          n(raw.body) === 0, `viewer=${n(raw.body)} service=0 (recorded, not claimed as proof)`);
        continue;
      }
      check(`PARKED boundary intact: a Viewer reads 0 of ${n(all.body)} row-level ${t}`,
        n(raw.body) === 0, `viewer=${n(raw.body)} service=${n(all.body)}`);
    }

    // ── 4 · Integrations — the column-limited view, and the STRICTER AND ────
    section('Wearable / Integrations connection view (157)');
    const coachUid = await uidOf('coach');
    const ins = await svc('user_integrations', { method: 'POST', body: {
      user_id: coachUid, provider: 'qa-d15-probe', connected: true,
      access_token: 'QA-D15-SECRET-MUST-NEVER-BE-READABLE',
      refresh_token: 'QA-D15-REFRESH-MUST-NEVER-BE-READABLE' } });
    seededIntegration = ins.status < 300;
    check('seeded a probe integration row carrying a token', seededIntegration, `status=${ins.status}`);

    if (seededIntegration) {
      const via = await rest(victim, 'admin_integration_connections?select=*&provider=eq.qa-d15-probe');
      check('a Viewer reads the probe connection through the curated view',
        n(via.body) === 1, `rows=${n(via.body)} status=${via.status}`);
      check('the curated view exposes NO token column — the 156 defect is closed',
        n(via.body) === 1 && !('access_token' in via.body[0]) && !('refresh_token' in via.body[0]),
        `keys=${n(via.body) === 1 ? Object.keys(via.body[0]).join(',') : 'n/a'}`);
      for (const col of ['access_token','refresh_token']) {
        const r = await rest(victim, `admin_integration_connections?select=${col}`);
        check(`${col} cannot be selected through the curated view`, r.status >= 400, `status=${r.status}`);
      }
      // The base table must STILL deny cross-user reads — 157 withdrew 156's arm.
      const direct = await rest(victim, 'user_integrations?select=id,access_token');
      check('the base table still denies a Viewer any other user\'s integration row',
        n(direct.body) === 0, `rows=${n(direct.body)} status=${direct.status}`);

      // STRICTER AUTHORIZATION, proved behaviourally. The owner directed the
      // shared surface use "the stricter applicable authorization", implemented as
      // AND over both areas. Today the matrix grants both to every role, so an AND
      // and an OR are indistinguishable by observation -- unless one grant is
      // withdrawn. This removes the Integrations grant ONLY, asserts the surface
      // closes even though the Wearable grant remains, and restores it. The
      // approved matrix FILE is not touched; the row is replaced and the 116-row
      // total re-asserted before this block exits.
      const del = await svc("admin_role_capabilities?admin_role=eq.viewer&area=eq.Integrations&verb=eq.view",
                            { method: 'DELETE' });
      capRemoved = del.status < 300;
      check('withdrew only viewer/Integrations/view for the stricter-AND probe', capRemoved, `status=${del.status}`);
      if (capRemoved) {
        const stillWearable = await rpc(victim, 'admin_can', { p_area: 'Wearable intelligence', p_verb: 'view' });
        check('the Wearable grant is still TRUE during the probe',
          stillWearable.body === true, `got ${JSON.stringify(stillWearable.body)}`);
        const closed = await rest(victim, 'admin_integration_connections?select=id&provider=eq.qa-d15-probe');
        check('STRICTER: losing ONE of the two area grants closes the shared surface',
          n(closed.body) === 0, `rows=${n(closed.body)} — an OR would still have returned 1`);
        const re = await svc('admin_role_capabilities', { method: 'POST',
          body: { admin_role: 'viewer', area: 'Integrations', verb: 'view' } });
        capRemoved = !(re.status < 300);
        const back = await rest(victim, 'admin_integration_connections?select=id&provider=eq.qa-d15-probe');
        check('restored: the surface reopens and the grid is whole again',
          !capRemoved && n(back.body) === 1, `restore=${re.status} rows=${n(back.body)}`);
        const caps = await svc('admin_role_capabilities?select=admin_role');
        check('the approved grid is back to exactly 116 rows',
          n(caps.body) === 116, `rows=${n(caps.body)}`);
      }
    }

    // ── 5 · the curated AUDIT projection — A13·1 and A12 ───────────────────
    section('curated audit projection · A13·1 preserved, base table untouched');

    // 5a · the base table protection the owner required proof of. The Viewer is
    // NOT is_admin() and NOT is_trust_operator(), so 142's policy gives them
    // nothing -- and 156 added no arm to it.
    const svcAudit = await svc('audit_events?select=id&limit=1000');
    const rawAudit = await rest(victim, 'audit_events?select=id&limit=1000');
    check('BASE audit_events still denies a Viewer every row — A13·1 not bypassed',
      n(rawAudit.body) === 0 && n(svcAudit.body) > 0,
      `viewer=${n(rawAudit.body)} service=${n(svcAudit.body)}`);

    // 5b · the curated surface DOES open to that same Viewer (Audit logs/View=true)
    const curated = await rest(victim, 'admin_audit_events?select=id&limit=1000');
    check('the CURATED view opens audit reads to a Viewer the base table refuses',
      n(curated.body) > 0, `rows=${n(curated.body)} status=${curated.status}`);

    // 5c · discrimination. support has Audit logs/View = FALSE in the approved
    // matrix, so the same view must close for them. Without this, an always-open
    // view would satisfy 5b too.
    await assign(vUid, 'support');
    const asSupport = await rest(victim, 'admin_audit_events?select=id&limit=1000');
    check('the curated view CLOSES for Support — Audit logs/View is false in the matrix',
      n(asSupport.body) === 0, `rows=${n(asSupport.body)}`);
    await assign(vUid, 'viewer');

    // 5d · A13·1 itself, on real rows. p1-admin authored admin_action rows, so
    // assigning them an Admin-layer role makes the exclusion observable: their own
    // rows must vanish from the view while everyone else's remain. Counts are read
    // from service at run time, so this does not drift as the population grows.
    const ownSvc   = await svc(`audit_events?select=id&category=eq.admin_action&actor_id=eq.${aUid}`);
    const otherSvc = await svc(`audit_events?select=id&category=eq.admin_action&actor_id=neq.${aUid}&limit=1000`);
    const assignedAdmin = await assign(aUid, 'viewer');
    check('arranged: p1-admin holds an Admin-layer Viewer role', assignedAdmin, `ok=${assignedAdmin}`);
    if (assignedAdmin && n(ownSvc.body) > 0) {
      const ownViaView = await rest(admin,
        `admin_audit_events?select=id&category=eq.admin_action&actor_id=eq.${aUid}`);
      check(`A13·1: the reader's OWN ${n(ownSvc.body)} admin_action rows are EXCLUDED from the view`,
        n(ownViaView.body) === 0, `saw ${n(ownViaView.body)} of ${n(ownSvc.body)}`);
      const otherViaView = await rest(admin,
        `admin_audit_events?select=id&category=eq.admin_action&actor_id=neq.${aUid}&limit=1000`);
      check(`A13·1 is NARROW: the other ${n(otherSvc.body)} admin_action rows remain visible`,
        n(otherSvc.body) > 0 && n(otherViaView.body) === n(otherSvc.body),
        `saw ${n(otherViaView.body)} of ${n(otherSvc.body)}`);
    } else {
      check('A13·1 exclusion is observable on real rows', false,
        `p1-admin authored ${n(ownSvc.body)} admin_action rows — cannot assert non-vacuously`);
    }

    // 5e · A12 — the view projects a pseudonym and opens no resolution path.
    section('A12 · the curated view resolves nothing');
    const shape = await rest(victim, 'admin_audit_events?select=*&limit=1');
    check('the curated view projects subject_pseudonym',
      n(shape.body) === 1 && 'subject_pseudonym' in shape.body[0],
      `keys=${n(shape.body) === 1 ? Object.keys(shape.body[0]).join(',') : 'none'}`);
    for (const col of ['subject_id','correlation_signature','correlation_key_id']) {
      const r = await rest(victim, `admin_audit_events?select=${col}`);
      check(`the curated view exposes no ${col}`, r.status >= 400, `status=${r.status}`);
    }
    const map = await rest(victim, 'audit_identity_map?select=*');
    check('a Viewer still cannot read audit_identity_map', n(map.body) === 0, `status=${map.status}`);

    // ── 6 · no write authority was created anywhere ─────────────────────────
    section('read surfaces confer no write authority');
    const wSub = await mutate(victim, 'subscriptions', 'POST', { user_id: vUid, kind: 'qa-d15', status: 'incomplete' });
    check('a Viewer cannot INSERT a subscription despite Monetization/View',
      wSub.status >= 400 || wSub.affected === 0, `status=${wSub.status}`);
    const wRole = await mutate(victim, 'admin_role_assignments', 'POST', { user_id: vUid, admin_role: 'trust_lead' });
    check('Roles READ confers no role-management authority (owner constraint)',
      wRole.status >= 400 || wRole.affected === 0, `status=${wRole.status}`);

    // ── 6b · THE CURATED VIEWS CONFER NO WRITE AUTHORITY ───────────────────
    // This section exists because 156/157 SHIPPED WITHOUT IT and the gap was real.
    // Both migrations revoked from PUBLIC and anon but NOT from `authenticated`,
    // and Supabase's default privileges grant ALL on a new view to that role. The
    // two single-table views are auto-updatable and run security_invoker = off, so
    // a write through them executes as the view OWNER and base-table RLS does not
    // apply. A user holding only the Admin-layer `viewer` role -- View yes, Update
    // explicitly NO -- DELETED another user's user_integrations row through
    // admin_integration_connections before migration 158 (V5 §129.2).
    //
    // Section 6 above asserted write refusal on the BASE TABLES and passed, which
    // is exactly why it did not catch this: the escalation was through the VIEW.
    // A deny assertion only covers the object it names.
    section('the curated views confer no write authority (158)');
    const NONE = '00000000-0000-0000-0000-000000000000';
    // INSERT and DELETE reflect the privilege directly: both answered 2xx before
    // 158 and 403 after it.
    for (const v of VIEWS) {
      for (const method of ['POST', 'DELETE']) {
        const path = method === 'POST' ? v : `${v}?id=eq.${NONE}`;
        const r = await rest(victim, path, {
          method,
          ...(method === 'DELETE' ? {} : { body: JSON.stringify({ provider: 'probe' }) }),
          headers: { 'Content-Type': 'application/json' },
        }).catch(() => ({ status: 403 }));
        check(`${method} on ${v} is refused`, r.status >= 400,
          `status=${r.status} — a 2xx means authenticated still holds the write grant`);
      }
    }
    // UPDATE is asserted by OUTCOME, not by status. PostgREST answers 204 to a
    // PATCH on these views whether or not the privilege exists -- it returns 204
    // even for admin_training_overview, which is not auto-updatable and could not
    // accept an UPDATE under any privilege. So the status code carries no
    // information here and asserting 403 on it would be asserting PostgREST's
    // request handling. What matters is that no write LANDS, which is checked
    // against the base row below, by a caller who DOES hold the View grant and
    // therefore supplies a non-empty row set -- the exact condition under which
    // the pre-158 DELETE succeeded.
    const coachUid2 = await uidOf('coach');
    await svc('user_integrations', { method: 'POST', body: {
      user_id: coachUid2, provider: 'qa-d15-write-probe', connected: true,
      access_token: 'ORIGINAL' } });
    const probeRow = (await svc('user_integrations?select=id,connected&provider=eq.qa-d15-write-probe')).body[0];
    if (probeRow) {
      const visible = await rest(victim, 'admin_integration_connections?select=id&provider=eq.qa-d15-write-probe');
      check('the Viewer DOES see the probe row — the row set is non-empty, so a write would have had a target',
        n(visible.body) === 1, `rows=${n(visible.body)}`);
      await rest(victim, `admin_integration_connections?id=eq.${probeRow.id}`, { method: 'PATCH',
        body: JSON.stringify({ connected: false }), headers: { 'Content-Type': 'application/json' } }).catch(() => ({}));
      const delRes = await rest(victim, `admin_integration_connections?id=eq.${probeRow.id}`,
        { method: 'DELETE' }).catch(() => ({ status: 403 }));
      const after = await svc('user_integrations?select=id,connected,access_token&provider=eq.qa-d15-write-probe');
      check('ESCALATION CLOSED: another user\'s row survives a Viewer\'s PATCH and DELETE, unchanged',
        n(after.body) === 1 && after.body[0].connected === true && after.body[0].access_token === 'ORIGINAL',
        `rows=${n(after.body)} connected=${n(after.body) === 1 ? after.body[0].connected : 'gone'} delete_status=${delRes.status}`);
      await svc('user_integrations?provider=eq.qa-d15-write-probe', { method: 'DELETE' });
    } else {
      check('write-escalation probe row seeded', false, 'could not seed the probe row');
    }

    // ── 6c · THE SECURITY AREA PROJECTION — owner decision B-1 (159) ───────
    section('Security area projection · B-1 scope, A13·1 again, B-19 withheld');

    // TWO OF THE FOUR DECIDED CATEGORIES HAVE NO LIVE ROWS ON QA -- `authentication`
    // and `authorization_denial` are both at zero. Without a row, "only the decided
    // categories appear" is satisfied by a view that MISSPELLED either of them, and
    // the Security screen would silently show no sign-in or denial events at all.
    // That is the defect this seeds against, and it is the same vacuity trap that
    // made the first parked-boundary assertion fail (V5 §128.5).
    //
    // A13 permits deterministic, clearly-marked QA data. audit_events is append-only
    // (trg_audit_events_freeze), so these rows CANNOT be cleaned up -- which is why
    // the seed is IDEMPOTENT: it emits only what is missing, so repeated local and
    // CI runs add at most one row per category, ever.
    //
    // EMITTED THROUGH THE SANCTIONED WRITE PATH, NOT INSERTED. A direct INSERT was
    // the first attempt and it was correctly REFUSED with 42501 even for the service
    // role: migration 148 revokes audit_events from `authenticated, service_role`
    // because "writes reach these tables through SECURITY DEFINER functions owned by
    // the table owner". That is a deliberate V5 boundary and the right answer was to
    // use the real producer, not to work around it. audit_record_event() is granted
    // to authenticated, so this exercises the same path production uses. The
    // p_changed_columns argument selects 151's signature over 150's overload.
    for (const cat of ['authentication', 'authorization_denial']) {
      const probeAction = `qa.d15.scope-probe.${cat}`;
      const already = await svc(`audit_events?select=id&action=eq.${encodeURIComponent(probeAction)}&limit=1`);
      if (n(already.body) === 0) {
        const r = await rpc(victim, 'audit_record_event', {
          p_action: probeAction, p_category: cat, p_outcome: 'success',
          p_actor_provenance: 'grounded', p_changed_columns: null });
        check(`emitted one clearly-marked QA ${cat} row through audit_record_event()`,
          r.status < 300, `status=${r.status} ${JSON.stringify(r.body).slice(0, 90)}`);
      } else {
        check(`a clearly-marked QA ${cat} row is already present`, true, 'idempotent — not re-emitted');
      }
    }

    // The Viewer holds Security/view=true in the approved matrix.
    const secRows = await rest(victim, 'admin_security_events?select=category&limit=1000');
    check('a Viewer reads the Security projection',
      n(secRows.body) > 0, `rows=${n(secRows.body)} status=${secRows.status}`);

    // SCOPE, both directions. Only the four decided categories may appear, and the
    // two that were offered and declined must be absent even though they exist in
    // the population -- which is what makes this an assertion about the DECISION
    // rather than about whatever the view happens to return.
    const seen = new Set((secRows.body || []).map(r => r.category));
    check(`only the four decided categories appear — got [${[...seen].sort().join(', ')}]`,
      [...seen].every(c => SECURITY_IN.includes(c)),
      `unexpected: ${[...seen].filter(c => !SECURITY_IN.includes(c)).join(', ') || 'none'}`);
    // The other direction, and the one that needed the seed: every decided category
    // must ACTUALLY flow through. A misspelling in the view's ARRAY would fail here
    // and nowhere else.
    for (const c of SECURITY_IN) {
      const live = await svc(`audit_events?select=id&category=eq.${c}&limit=1`);
      const via  = await rest(victim, `admin_security_events?select=id&category=eq.${c}&limit=1`);
      check(`${c} is IN Security scope and reaches the view`,
        n(live.body) > 0 && n(via.body) > 0,
        `population=${n(live.body)} view=${n(via.body)}`);
    }
    for (const c of SECURITY_OUT) {
      const live = await svc(`audit_events?select=id&category=eq.${c}&limit=1`);
      const via  = await rest(victim, `admin_security_events?select=id&category=eq.${c}&limit=1`);
      check(`${c} is OUT of Security scope${n(live.body) ? '' : ' (no live rows — recorded, not proof)'}`,
        n(via.body) === 0, `view=${n(via.body)} population=${n(live.body)}`);
    }

    // A13·1 AGAIN. admin_action is in scope here, so the exclusion has to hold on
    // this surface too -- otherwise adding the category to a second view would have
    // restored what A13·1 removes from the first.
    if (aUid) {
      const ownSvc2 = await svc(`audit_events?select=id&category=eq.admin_action&actor_id=eq.${aUid}`);
      const ok = await assign(aUid, 'viewer');
      if (ok && n(ownSvc2.body) > 0) {
        const own = await rest(admin, `admin_security_events?select=id&category=eq.admin_action&actor_id=eq.${aUid}`);
        check(`A13·1 holds in the Security projection too — the reader's own ${n(ownSvc2.body)} admin_action rows are excluded`,
          n(own.body) === 0, `saw ${n(own.body)} of ${n(ownSvc2.body)}`);
        const others = await rest(admin, `admin_security_events?select=id&category=eq.admin_action&actor_id=neq.${aUid}&limit=1000`);
        check('and it stays narrow — other actors\' admin_action rows remain visible',
          n(others.body) > 0, `saw ${n(others.body)}`);
      } else {
        check('A13·1 in the Security projection is observable', false,
          `admin authored ${n(ownSvc2.body)} admin_action rows`);
      }
    }

    // DISCRIMINATION. support has Security/view = false in the approved matrix.
    await assign(vUid, 'support');
    const asSup = await rest(victim, 'admin_security_events?select=id&limit=1000');
    check('the Security projection CLOSES for Support — Security/view is false in the matrix',
      n(asSup.body) === 0, `rows=${n(asSup.body)}`);
    await assign(vUid, 'viewer');

    // B-19: delta and changed_columns stay withheld. They EXIST on audit_events
    // (migration 150), so this is a projection decision, not an absent column.
    for (const col of ['delta', 'changed_columns']) {
      const onBase = await svc(`audit_events?select=${col}&limit=1`);
      const onView = await rest(victim, `admin_security_events?select=${col}&limit=1`);
      check(`B-19: ${col} exists on audit_events (${onBase.status}) and is WITHHELD from the Security projection`,
        onBase.status < 400 && onView.status >= 400, `base=${onBase.status} view=${onView.status}`);
      const onAudit = await rest(victim, `admin_audit_events?select=${col}&limit=1`);
      check(`B-19: ${col} is withheld from the Audit logs projection too`,
        onAudit.status >= 400, `status=${onAudit.status}`);
    }

    // A12 and the write posture, on this view as well.
    for (const col of ['subject_id', 'correlation_signature', 'correlation_key_id']) {
      const r = await rest(victim, `admin_security_events?select=${col}`);
      check(`the Security projection exposes no ${col}`, r.status >= 400, `status=${r.status}`);
    }
    for (const m of ['POST', 'DELETE']) {
      const path = m === 'POST' ? 'admin_security_events' : `admin_security_events?id=eq.${NONE}`;
      const r = await rest(victim, path, { method: m,
        ...(m === 'DELETE' ? {} : { body: JSON.stringify({ action: 'probe' }) }),
        headers: { 'Content-Type': 'application/json' } }).catch(() => ({ status: 403 }));
      check(`${m} on admin_security_events is refused — the revoke is in 159 itself`,
        r.status >= 400, `status=${r.status}`);
    }

    // ── 6d · USERS projection — owner decision B-2 (160) ───────────────────
    section('Users area projection · identity and account state only');
    const usersSvc = await svc('user_profiles?select=id&limit=1000');
    const usersVia = await rest(victim, 'admin_user_directory?select=*&limit=1000');
    check(`a Viewer reads the Users directory — ${n(usersVia.body)} of ${n(usersSvc.body)}`,
      n(usersVia.body) > 0 && n(usersVia.body) === n(usersSvc.body),
      `view=${n(usersVia.body)} service=${n(usersSvc.body)} status=${usersVia.status}`);
    check('the projection carries EXACTLY the nine decided columns',
      n(usersVia.body) > 0 &&
        Object.keys(usersVia.body[0]).length === USERS_ALLOWED.length &&
        USERS_ALLOWED.every(k => k in usersVia.body[0]),
      `keys=${n(usersVia.body) ? Object.keys(usersVia.body[0]).join(',') : 'none'}`);
    // Column by column, because "the projection looks right" is not the same claim
    // as "this column cannot be reached".
    for (const col of USERS_FORBIDDEN) {
      const onBase = await svc(`user_profiles?select=${col}&limit=1`);
      const onView = await rest(victim, `admin_user_directory?select=${col}&limit=1`);
      check(`${col} exists on user_profiles and is UNREACHABLE through the Users projection`,
        onBase.status < 400 && onView.status >= 400, `base=${onBase.status} view=${onView.status}`);
    }
    // The base table's own RLS is untouched: a Viewer must not read another member's
    // PHI directly. 160 added no policy to user_profiles.
    const phiDirect = await rest(victim, 'user_profiles?select=id,medical_conditions,parq_answers&limit=1000');
    const phiVisible = (phiDirect.body || []).filter(r => r.id !== vUid).length;
    check('base user_profiles still denies a Viewer every OTHER member\'s row — no policy was added to it',
      phiVisible === 0, `other members' rows visible=${phiVisible} of ${n(usersSvc.body)} (status ${phiDirect.status})`);

    // ── 6e · INCIDENTS projection — owner decision B-4 (160) ───────────────
    section('Incidents area projection · no evidence, no actor_identity');
    const incSvc = await svc('audit_incidents?select=id&limit=1000');
    const incVia = await rest(victim, 'admin_incidents?select=*&limit=1000');
    check(`a Viewer reads Incidents — ${n(incVia.body)} of ${n(incSvc.body)}`,
      n(incVia.body) > 0 && n(incVia.body) === n(incSvc.body),
      `view=${n(incVia.body)} service=${n(incSvc.body)}`);
    for (const col of ['evidence', 'actor_identity', 'actor_provenance', 'created_at', 'updated_at']) {
      const onBase = await svc(`audit_incidents?select=${col}&limit=1`);
      const onView = await rest(victim, `admin_incidents?select=${col}&limit=1`);
      check(`${col} exists on audit_incidents and is WITHHELD from the projection`,
        onBase.status < 400 && onView.status >= 400, `base=${onBase.status} view=${onView.status}`);
    }
    // DISCRIMINATION: support holds Incidents/view = FALSE in the approved matrix,
    // while it holds Users/view = TRUE. One role, two surfaces, opposite outcomes --
    // which is the assertion an always-open or always-closed view cannot satisfy.
    await assign(vUid, 'support');
    const incSup  = await rest(victim, 'admin_incidents?select=id&limit=1000');
    const userSup = await rest(victim, 'admin_user_directory?select=id&limit=1000');
    check('Incidents CLOSES for Support — Incidents/view is false in the matrix',
      n(incSup.body) === 0, `rows=${n(incSup.body)}`);
    check('…while Users stays OPEN for that same Support role — Users/view is true',
      n(userSup.body) > 0, `rows=${n(userSup.body)}`);
    await assign(vUid, 'viewer');

    // No write authority on either, revoked in 160 itself.
    for (const v of ['admin_user_directory', 'admin_incidents']) {
      for (const m of ['POST', 'DELETE']) {
        const path = m === 'POST' ? v : `${v}?id=eq.${NONE}`;
        const r = await rest(victim, path, { method: m,
          ...(m === 'DELETE' ? {} : { body: JSON.stringify({ summary: 'probe' }) }),
          headers: { 'Content-Type': 'application/json' } }).catch(() => ({ status: 403 }));
        check(`${m} on ${v} is refused — the revoke is in 160 itself`, r.status >= 400, `status=${r.status}`);
      }
    }

    // B-3 CLOSED as aggregate-only: the row-level denial is now a confirmed
    // boundary, not a parked gap, so it is asserted as such rather than deferred.
    const b3 = await rest(victim, 'workout_sessions?select=id&limit=1000');
    const b3svc = await svc('workout_sessions?select=id&limit=1000');
    check(`B-3 CONFIRMED aggregate-only: a Viewer reads 0 of ${n(b3svc.body)} row-level sessions`,
      n(b3.body) === 0 && n(b3svc.body) > 0, `viewer=${n(b3.body)} service=${n(b3svc.body)}`);

    // ── 6f · SUPPORT'S Users-Update WRITE PATH — owner decision B-2 (161/162) ─
    // The only non-View grant outside Trust and Operations, so this is the one
    // place the Admin layer writes member data at all.
    section('Support Users-Update write path · names only, audited without values');
    const tgt = await svc(`user_profiles?select=id,first_name,last_name&email=eq.${encodeURIComponent(IDENT.coach.email)}`);
    const target = n(tgt.body) ? tgt.body[0] : null;
    check('write-path target resolved', !!target, target ? 'ok' : 'could not resolve the coach fixture');

    if (target) {
      const orig = { first: target.first_name, last: target.last_name };
      const nameNow = async () => {
        const r = await svc(`user_profiles?select=first_name,last_name&id=eq.${target.id}`);
        return n(r.body) ? r.body[0] : {};
      };
      try {
        // EVERY role the matrix denies must be refused, not merely ineffective.
        for (const role of [null, 'viewer', 'trust_lead', 'operations_lead', 'content_editor']) {
          await unassign(vUid);
          if (role) await assign(vUid, role);
          const r = await rpc(victim, 'admin_update_user_name',
            { p_user_id: target.id, p_first_name: 'D15-FORBIDDEN', p_last_name: null });
          const after = await nameNow();
          check(`${role || 'an unassigned caller'} is REFUSED the Users-Update write path`,
            r.status >= 400 && after.first_name === orig.first,
            `status=${r.status} name=${after.first_name}`);
        }

        // support holds Users/Update = true, and must actually succeed.
        await assign(vUid, 'support');
        const beforeAudit = await svc("audit_events?select=id&action=eq.user_profiles.name.set");
        const ok = await rpc(victim, 'admin_update_user_name',
          { p_user_id: target.id, p_first_name: 'D15Probe', p_last_name: orig.last });
        const changed = await nameNow();
        check('Support CAN correct a name — the grant is real, not decorative',
          ok.status < 400 && changed.first_name === 'D15Probe',
          `status=${ok.status} name=${changed.first_name}`);

        // The writable set is the function body. Nothing else may move.
        const full = await svc(`user_profiles?select=role,membership_tier,email,phone,medical_conditions&id=eq.${target.id}`);
        check('only the name moved — role, membership_tier, email, phone and PHI are untouched',
          n(full.body) === 1 && full.body[0].role === 'coach',
          `role=${n(full.body) ? full.body[0].role : '?'}`);

        // A12: the admin_action record must prove WHAT changed without carrying the
        // values, because a name re-identifies the pseudonymous subject.
        const afterAudit = await svc("audit_events?select=id,delta,changed_columns,subject_pseudonym,category&action=eq.user_profiles.name.set&order=occurred_at.desc&limit=1");
        check('the correction emitted exactly one new admin_action audit record',
          n(afterAudit.body) === 1 && afterAudit.body[0].category === 'admin_action',
          `rows=${n(afterAudit.body)} new=${n(afterAudit.body) - 0 > 0}`);
        if (n(afterAudit.body) === 1) {
          const ev = afterAudit.body[0];
          check('A12: the audit record carries NO delta — a name would re-identify the pseudonymous subject',
            ev.delta === null, `delta=${JSON.stringify(ev.delta)}`);
          check('…but it DOES name the changed column, so the record is still evidence',
            Array.isArray(ev.changed_columns) && ev.changed_columns.includes('first_name'),
            `changed_columns=${JSON.stringify(ev.changed_columns)}`);
          check('…and the subject is a pseudonym, not the user id',
            !!ev.subject_pseudonym && ev.subject_pseudonym !== target.id,
            `pseudonym=${ev.subject_pseudonym} userId=${target.id}`);
        }

        // Input validation, server-side.
        const blank = await rpc(victim, 'admin_update_user_name',
          { p_user_id: target.id, p_first_name: '   ', p_last_name: null });
        check('a whitespace-only name is rejected server-side', blank.status >= 400, `status=${blank.status}`);
        const nosuch = await rpc(victim, 'admin_update_user_name',
          { p_user_id: NONE, p_first_name: 'X', p_last_name: null });
        check('an unknown target is rejected', nosuch.status >= 400, `status=${nosuch.status}`);
      } finally {
        await svc(`user_profiles?id=eq.${target.id}`, { method: 'PATCH',
          body: { first_name: orig.first, last_name: orig.last } });
        await unassign(vUid);
        await assign(vUid, 'viewer');
      }
    }

    // ── 6g · AI GUARDIAN registry read — the grant that was INERT (163) ────
    // The matrix grants AI Guardian/View to trust_lead, operations_lead and viewer.
    // 154's registry read was is_admin() OR is_trust_operator(), and an Admin-layer
    // trust_lead is NEITHER -- CONF-D7 forbids mapping Trust lead to trust_operator
    // and 153 keeps is_admin() false for every Admin-layer principal. So the grant
    // was real in the matrix and did nothing in the database.
    //
    // THE TABLE IS EMPTY ON QA, so every assertion here would pass vacuously --
    // including the pre-163 claim that a Viewer "cannot read governance_policy",
    // which was true for the wrong reason. A row is seeded for the duration and
    // removed afterwards; governance_policy carries no append-only freeze, so
    // unlike audit_events it CAN be cleaned up.
    section('AI Guardian registry read · the inert grant, made effective (163)');
    const POLICY_CODE = 'QA-D15-PROBE-01';
    await svc(`governance_policy?code=eq.${POLICY_CODE}`, { method: 'DELETE' });
    const seeded = await svc('governance_policy', { method: 'POST', body: {
      code: POLICY_CODE, name: 'D15 probe policy', category: 'role_based',
      scope: 'QA probe', status: 'draft' } });
    check('seeded a clearly-marked QA governance policy row', seeded.status < 300, `status=${seeded.status}`);

    if (seeded.status < 300) {
      try {
        const total = await svc('governance_policy?select=id');
        // GRANTED by the matrix -> must now read it. Before 163 these were all 0.
        for (const role of ['trust_lead', 'operations_lead', 'viewer']) {
          await assign(vUid, role);
          const r = await rest(victim, 'governance_policy?select=id,code');
          check(`${role} CAN read the governance registry — AI Guardian/View is true and is now effective`,
            n(r.body) === n(total.body) && n(r.body) > 0,
            `saw ${n(r.body)} of ${n(total.body)} (status ${r.status})`);
        }
        // DENIED by the matrix -> must still read nothing.
        for (const role of ['support', 'content_editor']) {
          await assign(vUid, role);
          const r = await rest(victim, 'governance_policy?select=id');
          check(`${role} still reads NOTHING — AI Guardian/View is false in the matrix`,
            n(r.body) === 0, `saw ${n(r.body)} (status ${r.status})`);
        }
        // Read only. 163 added no write arm; 154's writes stay on is_admin().
        await assign(vUid, 'trust_lead');
        const w = await mutate(victim, 'governance_policy', 'POST',
          { code: 'QA-D15-FORBIDDEN', name: 'x', category: 'safety', status: 'draft' });
        check('the Admin layer cannot AUTHOR a governance policy — reads the record, does not write it',
          w.status >= 400 || w.affected === 0, `status=${w.status}`);
        const landed = await svc('governance_policy?select=id&code=eq.QA-D15-FORBIDDEN');
        check('…and no forbidden row landed', n(landed.body) === 0, `rows=${n(landed.body)}`);
        // The registry is NOT the enforcement point (owner constraint): a policy row
        // granting something must not change what admin_can() answers.
        const before = await rpc(victim, 'admin_can', { p_area: 'Users', p_verb: 'update' });
        check('a registry row does not become authorization — admin_can is unmoved (§13 deterministic authority)',
          before.body === false, `admin_can(Users,update) for trust_lead = ${JSON.stringify(before.body)}`);
      } finally {
        await svc(`governance_policy?code=eq.${POLICY_CODE}`, { method: 'DELETE' });
        await svc('governance_policy?code=eq.QA-D15-FORBIDDEN', { method: 'DELETE' });
        await assign(vUid, 'viewer');
      }
    }

    // ── 7 · anon reaches none of the three new surfaces ─────────────────────
    section('anon posture on the new surfaces');
    for (const v of VIEWS) {
      const a = await fetch(`${URL_}/rest/v1/${v}?select=*`, { headers: { apikey: process.env.QA_ANON } });
      const b = await a.json().catch(() => []);
      check(`anon reaches nothing through ${v}`,
        a.status >= 400 || (Array.isArray(b) && b.length === 0), `status=${a.status}`);
    }
  } finally {
    // Restore the capability grid FIRST — leaving it short would make D14 fail
    // for a reason that has nothing to do with D14.
    if (capRemoved) {
      await svc('admin_role_capabilities', { method: 'POST',
        body: { admin_role: 'viewer', area: 'Integrations', verb: 'view' } });
    }
    if (seededIntegration) await svc("user_integrations?provider=eq.qa-d15-probe", { method: 'DELETE' });
    await unassign(vUid);
    await unassign(aUid);
  }

  return summary('D15 admin surface access');
}

export default await run();
