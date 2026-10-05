// D13 · GRADED ADMIN AUTHORIZATION — the matrix-INDEPENDENT half, live against QA.
//
// Covers migrations 153 (admin layer) and 154 (governance registry). V5 §113 is
// the specification, §113.3 the least-privilege proof, §118.3 the QA packet.
//
// WHY THIS SUITE IS UNREGISTERED. 153/154 are authored and declared PENDING on QA
// (supabase/expected_applied.json) because no owner authorization to apply them
// exists. Registering it in run.mjs would make CI fail on a migration that is
// deliberately unapplied — the opposite of evidence. It is registered the moment
// they are applied.
//
// WHY IT NEEDS NO CAPABILITY DATA. Every assertion below holds with
// admin_role_capabilities EMPTY. The 85-cell matrix is a separate blocker (V5
// §116) and gates only the grant-specific tests of §A6. These are the structural
// and separation properties, and they are exactly the ones a seeding mistake
// would break.
//
// It CLEANS UP after itself: unlike d12, these tables carry no append-only freeze,
// so the fixture assignment row is removed in a finally block.
import { URL_, SERVICE, IDENT, signIn, rpc, mutate, svc,
         check, section, summary, beginSuite } from './lib.mjs';

export default async function run() {
  beginSuite();

  // ── 0 · are the migrations applied at all? ────────────────────────────────
  // Stated first so a run against an un-migrated QA reports WHY it asserted
  // nothing, rather than failing 20 times for one reason (V5 §28.9's lesson).
  const probe = await svc('/rest/v1/admin_role_capabilities?select=admin_role&limit=1');
  if (probe.status === 404 || (probe.body && /does not exist|schema cache/i.test(JSON.stringify(probe.body)))) {
    check('migrations 153/154 are applied to QA', false,
      'admin_role_capabilities not reachable — 153 is PENDING, nothing below was asserted');
    return summary('D13 admin graded authorization');
  }
  check('migrations 153/154 are applied to QA', true, 'capability table reachable');

  const victim = await signIn('victim');   // role='client' — never role='admin'
  let arranged = false;

  try {
    // ── 1 · deny-by-default, the property the whole design rests on ──────────
    section('deny-by-default with an empty capability grid');
    const empty = await svc('/rest/v1/admin_role_capabilities?select=admin_role');
    check('admin_role_capabilities is empty', Array.isArray(empty.body) && empty.body.length === 0,
      `rows=${Array.isArray(empty.body) ? empty.body.length : '?'}`);

    for (const [area, verb] of [['Security', 'View'], ['Audit logs', 'Manage'], ['Users', 'Update']]) {
      const r = await rpc(victim, 'admin_can', { p_area: area, p_verb: verb });
      check(`admin_can('${area}','${verb}') is false`, r.body === false, `got ${JSON.stringify(r.body)}`);
    }

    // ── 2 · the Admin layer does NOT confer legacy admin — §113.3 proof ──────
    section('an Admin-layer member is not a legacy admin');
    const me = await svc(`/rest/v1/user_profiles?select=id&email=eq.${encodeURIComponent(IDENT.victim.email)}`);
    const uid = Array.isArray(me.body) && me.body[0] ? me.body[0].id : null;
    check('fixture identity resolved', !!uid, uid ? 'ok' : 'could not resolve victim id');

    if (uid) {
      const ins = await svc('/rest/v1/admin_role_assignments', {
        method: 'POST', headers: { Prefer: 'return=representation' },
        body: JSON.stringify({ user_id: uid, admin_role: 'viewer' }),
      });
      arranged = ins.status < 300;
      check('arranged: victim holds the Viewer Admin role', arranged, `status=${ins.status}`);

      if (arranged) {
        const isMember = await rpc(victim, 'is_admin_member');
        check('is_admin_member() is TRUE for the assigned user', isMember.body === true, `got ${JSON.stringify(isMember.body)}`);

        // THE assertion. A Viewer must not satisfy is_admin(), or they inherit
        // all 14 inline RLS clauses that name 'admin' (V5 §107.3).
        const isAdmin = await rpc(victim, 'is_admin');
        check('is_admin() is FALSE for a Viewer — no legacy admin inherited',
          isAdmin.body === false, `got ${JSON.stringify(isAdmin.body)}`);

        const isTrust = await rpc(victim, 'is_trust_operator');
        check('is_trust_operator() is FALSE — Trust separation holds', isTrust.body === false, `got ${JSON.stringify(isTrust.body)}`);

        const isEras = await rpc(victim, 'is_erasure_executor');
        check('is_erasure_executor() is FALSE — erasure separation holds', isEras.body === false, `got ${JSON.stringify(isEras.body)}`);

        // ── 3 · the layer cannot escalate itself ────────────────────────────
        section('self-escalation is refused');
        const selfGrant = await mutate(victim, '/rest/v1/admin_role_capabilities', 'POST',
          { admin_role: 'viewer', area: 'Security', verb: 'manage' });
        check('a Viewer cannot grant themselves a capability',
          selfGrant.status >= 400 || selfGrant.affected === 0, `status=${selfGrant.status}`);

        const selfAssign = await mutate(victim, '/rest/v1/admin_role_assignments', 'POST',
          { user_id: uid, admin_role: 'trust_lead' });
        check('a Viewer cannot promote their own Admin role',
          selfAssign.status >= 400 || selfAssign.affected === 0, `status=${selfAssign.status}`);

        // ── 4 · A12 — the layer opens no identity path ──────────────────────
        section('A12 · no new re-identification path');
        const map = await mutate(victim, '/rest/v1/audit_identity_map?select=*', 'GET', null)
          .catch(() => ({ status: 403 }));
        check('a Viewer cannot read audit_identity_map',
          !map || map.status >= 400 || (Array.isArray(map.body) && map.body.length === 0),
          `status=${map && map.status}`);

        // ── 5 · governance registry is readable only to admin/Trust ─────────
        section('governance registry (154)');
        const gp = await mutate(victim, '/rest/v1/governance_policy?select=code', 'GET', null)
          .catch(() => ({ status: 403 }));
        check('a Viewer cannot read governance_policy',
          !gp || gp.status >= 400 || (Array.isArray(gp.body) && gp.body.length === 0),
          `status=${gp && gp.status}`);
      }
    }

    // ── 6 · anon reaches nothing ────────────────────────────────────────────
    section('anon posture');
    for (const t of ['admin_role_assignments', 'admin_role_capabilities', 'governance_policy']) {
      const a = await fetch(`${URL_}/rest/v1/${t}?select=*`, { headers: { apikey: process.env.QA_ANON } });
      check(`anon cannot read ${t}`, a.status >= 400 || (await a.json().catch(() => [])).length === 0,
        `status=${a.status}`);
    }
  } finally {
    if (arranged) {
      const me = await svc(`/rest/v1/user_profiles?select=id&email=eq.${encodeURIComponent(IDENT.victim.email)}`);
      const uid = Array.isArray(me.body) && me.body[0] ? me.body[0].id : null;
      if (uid) await svc(`/rest/v1/admin_role_assignments?user_id=eq.${uid}`, { method: 'DELETE' });
    }
  }

  return summary('D13 admin graded authorization');
}

if (import.meta.url === `file://${process.argv[1]}`) {
  run().then((f) => process.exit(f ? 1 : 0));
}
