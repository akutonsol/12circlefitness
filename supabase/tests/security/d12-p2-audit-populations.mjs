// P2 · the four audit/observability populations, the identity mapping, severance
// and the audit read path — LIVE against QA.
//
// Covers migrations 142–147. Every assertion states the SECURE expectation and
// cites the ruling it comes from; V5 §75–§79 carry the specification and the
// traceability matrix.
//
// ONE PROPERTY OF THIS SUITE IS UNUSUAL AND DELIBERATE: it cannot clean up after
// itself. audit_events is append-only by A11 and its freeze trigger refuses
// DELETE to every caller including service_role, so the rows this suite writes
// are PERMANENT on QA. That is the population behaving as ruled, not a leak. Rows
// are tagged with a run-unique marker so they remain attributable.
import { URL_, ANON, SERVICE, IDENT, signIn, rest, svc, mutate, rpc,
         check, section, summary, beginSuite, n } from './lib.mjs';

const RUN = `p2probe-${Date.now()}`;
const H = (tok) => ({ apikey: ANON, Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' });
const SH = { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, 'Content-Type': 'application/json' };

// ── dedicated probe identities, so no shared fixture's role is disturbed ─────
async function mkUser(tag) {
  const email = `${RUN}-${tag}@qa.12circle.test`;
  const pw = `P2-Probe-${tag}-2026!`;
  const r = await fetch(`${URL_}/auth/v1/admin/users`, {
    method: 'POST', headers: SH,
    body: JSON.stringify({ email, password: pw, email_confirm: true }),
  });
  const u = await r.json();
  return { id: u.id, email, pw };
}
async function tokenFor(u) {
  const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: ANON, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: u.email, password: u.pw }),
  });
  return (await r.json()).access_token;
}
async function setRole(id, role) {
  return fetch(`${URL_}/rest/v1/user_profiles?id=eq.${id}`, {
    method: 'PATCH', headers: { ...SH, Prefer: 'return=minimal' },
    body: JSON.stringify({ role }),
  });
}

const admin  = await mkUser('admin');
const trust  = await mkUser('trust');
const eraser = await mkUser('eraser');
const subj   = await mkUser('subject');
for (const [u, r] of [[admin,'admin'],[trust,'trust_operator'],[eraser,'erasure_executor']]) await setRole(u.id, r);
const adminTok  = await tokenFor(admin);
const trustTok  = await tokenFor(trust);
const eraserTok = await tokenFor(eraser);
const subjTok   = await tokenFor(subj);

check('fixture: four probe identities exist with their roles',
  !!(adminTok && trustTok && eraserTok && subjTok), `run=${RUN}`);

// ─────────────────────────────────────────────────────────────────────────────
section('A2 · admin_set_user_role EMITS an audit Event (§8.3 named this gap)');

const before = await fetch(`${URL_}/rest/v1/audit_events?select=id&category=eq.admin_action`, { headers: SH });
const nBefore = n(await before.json());

const setR = await fetch(`${URL_}/rest/v1/rpc/admin_set_user_role`, {
  method: 'POST', headers: H(adminTok),
  body: JSON.stringify({ target_user: subj.id, new_role: 'coach' }),
});
check('an admin CAN set a role through the sanctioned path', setR.status < 300, `status=${setR.status}`);

const after = await fetch(`${URL_}/rest/v1/audit_events?select=id,actor_id,subject_pseudonym,actor_provenance&category=eq.admin_action&order=occurred_at.desc&limit=1`, { headers: SH });
const rows = await after.json();
const afterAll = n(await (await fetch(`${URL_}/rest/v1/audit_events?select=id&category=eq.admin_action`, { headers: SH })).json());
check('the role change EMITTED an admin_action Event (A2 IN; A3 application arm)',
  afterAll === nBefore + 1, `${nBefore} -> ${afterAll}`);
const row = rows[0] ?? {};
check('the actor is the calling admin and provenance is GROUNDED (A3 sub-ruling 3)',
  row.actor_id === admin.id && row.actor_provenance === 'grounded',
  `actor=${row.actor_id === admin.id} provenance=${row.actor_provenance}`);

// ─────────────────────────────────────────────────────────────────────────────
section('A6 §8.9 · before/after delta — NON-PHI ONLY, phi_correction excluded');

// A6 lists admin actions among the nine delta-bearing categories and names the
// value they carry: "role". Migration 147 emitted without one because the column
// did not exist until 150.
const deltaRow = await (await fetch(`${URL_}/rest/v1/audit_events?select=delta&category=eq.admin_action&order=occurred_at.desc&limit=1`, { headers: SH })).json();
const dlt = deltaRow[0]?.delta ?? null;
check('the admin_action Event carries the role before/after pair (A6 — admin actions are delta-bearing)',
  !!dlt && dlt.before?.role && dlt.after?.role && dlt.before.role !== dlt.after.role,
  `before=${dlt?.before?.role} after=${dlt?.after?.role}`);

// A6: "PHI-CORRECTION DELTAS ARE EXCLUDED." Enforced as a constraint so a
// mislabelled record cannot put PHI into the ledger.
const phiDelta = await fetch(`${URL_}/rest/v1/rpc/audit_record_event`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ p_action: RUN, p_category: 'phi_correction', p_outcome: 'success',
                         p_delta: { before: { x: 1 }, after: { x: 2 } } }),
});
const phiDeltaRes = await phiDelta.json().catch(() => null);
check('a phi_correction Event carrying a delta is REFUSED (A6 excludes it by name)',
  phiDeltaRes === false, `result=${phiDeltaRes}`);

const occDelta = await fetch(`${URL_}/rest/v1/rpc/audit_record_event`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ p_action: RUN, p_category: 'phi_read', p_outcome: 'success',
                         p_delta: { before: {}, after: {} } }),
});
check('nor may one of A6\'s five OCCURRENCE categories carry a delta',
  (await occDelta.json().catch(() => null)) === false, 'phi_read + delta refused');

section('A12 ruling 2 · the subject is a PSEUDONYM, resolvable only through the map');

check('the recorded subject is NOT the target\'s real id',
  row.subject_pseudonym && row.subject_pseudonym !== subj.id,
  `pseudonym=${String(row.subject_pseudonym).slice(0,8)}… target=${subj.id.slice(0,8)}…`);

// Resolution is verified through the SANCTIONED PATH, not by reading the map.
// An earlier revision of this assertion queried audit_identity_map directly with
// service_role and passed -- until migration 148 revoked that grant, at which
// point it failed for the right reason. §19.3 permits resolution only "inside the
// audit read path", so asserting it any other way was testing a route the ruling
// forbids. The direct read is asserted separately, and must FAIL.
const viaPath = await rpc(trustTok, 'audit_read_events', { p_subject: subj.id, p_limit: 5 });
check('and it RESOLVES to the target — through the audit read path, the only place §19.3 allows',
  viaPath.status < 300 && n(viaPath.body) >= 1 && viaPath.body.every(r => r.subject_id === subj.id),
  `status=${viaPath.status} rows=${n(viaPath.body)}`);

// ─────────────────────────────────────────────────────────────────────────────
section('A11 · the Event population is FROZEN against every caller, service_role included');

const upd = await fetch(`${URL_}/rest/v1/audit_events?id=eq.${row.id}`, {
  method: 'PATCH', headers: SH, body: JSON.stringify({ outcome: 'failure' }),
});
check('service_role CANNOT update an audit Event', upd.status >= 400, `status=${upd.status}`);
const del = await fetch(`${URL_}/rest/v1/audit_events?id=eq.${row.id}`, { method: 'DELETE', headers: SH });
check('service_role CANNOT delete an audit Event', del.status >= 400, `status=${del.status}`);
const intact = await (await fetch(`${URL_}/rest/v1/audit_events?select=outcome&id=eq.${row.id}`, { headers: SH })).json();
check('and the row is intact after both attempts', intact[0]?.outcome === 'success', `outcome=${intact[0]?.outcome}`);

// ─────────────────────────────────────────────────────────────────────────────
section('A13 · readers — sub-ruling 1 excludes an admin from their OWN admin actions');

const adminSees = await rest(adminTok, `audit_events?select=id&category=eq.admin_action&actor_id=eq.${admin.id}`);
check('the acting admin reads NONE of the admin_action rows they caused (A13 sub-ruling 1)',
  n(adminSees.body) === 0, `rows=${n(adminSees.body)}`);

const trustSees = await rest(trustTok, `audit_events?select=id&category=eq.admin_action&actor_id=eq.${admin.id}`);
check('the Trust operator DOES read them — that is the point of sub-ruling 1',
  n(trustSees.body) >= 1, `rows=${n(trustSees.body)}`);

const subjSees = await rest(subjTok, 'audit_events?select=id');
check('the SUBJECT reads nothing — §8.8: not a reader of any audit population',
  n(subjSees.body) === 0, `rows=${n(subjSees.body)}`);

const eraserSees = await rest(eraserTok, 'audit_events?select=id');
check('the erasure executor reads nothing (§8.18·Q2 — never both authorities)',
  n(eraserSees.body) === 0, `rows=${n(eraserSees.body)}`);

// ─────────────────────────────────────────────────────────────────────────────
section('§19.3 · resolution happens ONLY inside the audit read path');

const pathAsTrust = await rpc(trustTok, 'audit_read_events', { p_limit: 5 });
check('the read path serves an entitled reader and RESOLVES the subject',
  pathAsTrust.status < 300 && n(pathAsTrust.body) >= 1
    && pathAsTrust.body.some(r => r.subject_id), `status=${pathAsTrust.status} rows=${n(pathAsTrust.body)}`);

const mapDirect = await rest(trustTok, 'audit_identity_map?select=*');
check('NO client role may read the map directly (§8.20·Q1 — no policy grants any)',
  n(mapDirect.body) === 0 || mapDirect.status >= 400, `status=${mapDirect.status} rows=${n(mapDirect.body)}`);

// ─────────────────────────────────────────────────────────────────────────────
section('A12 ruling 1 · ANONYMISE-AND-RETAIN — severance keeps the ledger');

const severByTrust = await rpc(trustTok, 'audit_sever_identity', { p_subject: subj.id });
check('severance is REFUSED to the Trust operator (A12 ruling 6; §8.18·Q1)',
  severByTrust.status >= 400, `status=${severByTrust.status}`);

const severByEraser = await rpc(eraserTok, 'audit_sever_identity', { p_subject: subj.id });
check('severance SUCCEEDS for the erasure executor', severByEraser.status < 300 && severByEraser.body === true,
  `status=${severByEraser.status} result=${severByEraser.body}`);

const stillThere = await (await fetch(`${URL_}/rest/v1/audit_events?select=id&id=eq.${row.id}`, { headers: SH })).json();
check('the audit row is RETAINED after severance — the frozen row is never mutated',
  n(stillThere) === 1, `rows=${n(stillThere)}`);

const mapGone = await (await fetch(`${URL_}/rest/v1/audit_identity_map?select=pseudonym&subject_id=eq.${subj.id}`, { headers: SH })).json();
check('and the identity is no longer resolvable', n(mapGone) === 0, `map rows=${n(mapGone)}`);

// ─────────────────────────────────────────────────────────────────────────────
section('A11 · Control evidence has NO RUNTIME WRITE PATH');

const ceIns = await fetch(`${URL_}/rest/v1/audit_control_evidence`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ requirement: RUN, implementation_location: 'x', test_evidence: 'y', result: 'pass', date_version: 'v1', owner: 'probe' }),
});
check('not even service_role may INSERT control evidence (A11 NO RUNTIME WRITE PATH)',
  ceIns.status >= 400, `status=${ceIns.status}`);

// Migration 148. The FIRST live run of this suite failed the assertion above with
// 201: Supabase's ALTER DEFAULT PRIVILEGES grants ALL on every new public table to
// authenticated and service_role, so 142-146's GRANT SELECT statements were
// additive no-ops and service_role -- which BYPASSES RLS -- held full DML. A bare
// postgres has no such defaults, which is why the local rung could not see it.
section('A3 sub-ruling 5 · service_role is CONSTRAINED where no freeze bound it');

const mapDel = await fetch(`${URL_}/rest/v1/audit_identity_map?subject_id=eq.${subj.id}`, {
  method: 'DELETE', headers: SH,
});
check('service_role CANNOT sever an identity directly — only the executor\'s path may (A12 ruling 6)',
  mapDel.status >= 400, `status=${mapDel.status}`);

const mapIns = await fetch(`${URL_}/rest/v1/audit_identity_map`, {
  method: 'POST', headers: SH, body: JSON.stringify({ subject_id: admin.id }),
});
check('service_role CANNOT write the identity map directly (§8.20·Q1)',
  mapIns.status >= 400, `status=${mapIns.status}`);

// ─────────────────────────────────────────────────────────────────────────────
section('A1 pop. 2 · the Incident population is WRITE-CLOSED — its RPC is unbuilt');

// A3 §8.5 gives the Incident population the write path "RPC + application". No
// RPC exists, because NO RULING DETERMINES WHO MAY OPEN AN INCIDENT: the record
// specifies the eleven fields (V5_DECISION_RESOLUTION:114), the readers (A13),
// the mutation semantics (A11 APPEND-STATE-TRANSITIONS), the retention (A12
// ruling 4) and the write-path MECHANISM — but not the creating authority.
// Building an RPC would mean inventing that boundary. Until it is ruled the
// population is correctly write-closed, and these assertions hold it closed so
// the gap cannot be filled by accident. See V5 §81.
const incIns = await fetch(`${URL_}/rest/v1/audit_incidents`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ summary: RUN, occurred_at: new Date().toISOString(),
                         severity: 'High', actor_provenance: 'system' }),
});
check('service_role CANNOT create an incident — no write path is ruled yet (A3 §8.5)',
  incIns.status >= 400, `status=${incIns.status}`);

const incInsAuth = await mutate(trustTok, 'audit_incidents', 'POST',
  { summary: RUN, occurred_at: new Date().toISOString(), severity: 'High', actor_provenance: 'system' });
check('nor may the Trust operator — Trust reviews, it does not author (§19.2)',
  incInsAuth.status >= 400, `status=${incInsAuth.status}`);

const trIns = await fetch(`${URL_}/rest/v1/audit_incident_transitions`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ incident_id: subj.id, changed_field: 'x', changed_by_provenance: 'system' }),
});
check('nor may anyone forge a retained transition directly (A11 §8.6)',
  trIns.status >= 400, `status=${trIns.status}`);

section('D12 · the observability population carries no subject, and retention is bound');

const obsCols = await fetch(`${URL_}/rest/v1/observability_events?select=*&limit=1`, { headers: SH });
check('observability_events is reachable by service_role', obsCols.status === 200, `status=${obsCols.status}`);

// Migration 149. service_role's direct INSERT was revoked: §8.16·Q4 discharges
// this population's deferral "ON THE SAME TERMS AS THE AUDIT POPULATIONS —
// service_role is NOT the writer of record", and a direct grant made it exactly
// that. Writes now go through a definer function, as they do for the audit
// populations.
const obsDirect = await fetch(`${URL_}/rest/v1/observability_events`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ component: 'metric', retention_class: 'operational_90d' }),
});
check('service_role CANNOT insert observability directly — it is not the writer of record (§8.16·Q4)',
  obsDirect.status >= 400, `status=${obsDirect.status}`);

const obsRpc = await fetch(`${URL_}/rest/v1/rpc/observability_record`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ p_component: 'metric', p_retention_class: 'operational_90d' }),
});
const obsRpcOk = await obsRpc.json().catch(() => null);
check('but the definer write path accepts a correctly-classed record',
  obsRpc.status < 300 && obsRpcOk === true, `status=${obsRpc.status} result=${obsRpcOk}`);

const obsBad = await fetch(`${URL_}/rest/v1/rpc/observability_record`, {
  method: 'POST', headers: SH,
  body: JSON.stringify({ p_component: 'metric', p_retention_class: 'audit_6y' }),
});
const obsBadRes = await obsBad.json().catch(() => null);
check('a 6-year class still cannot attach to a non-audit component (§8.16·Q2)',
  obsBadRes === false, `result=${obsBadRes}`);

const obsRow = ((await (await fetch(`${URL_}/rest/v1/observability_events?select=*&order=recorded_at.desc&limit=1`, { headers: SH })).json())[0]) ?? {};
check('and the stored record carries NO subject identifier (D12·Q5)',
  !('subject_id' in obsRow) && !('user_id' in obsRow), Object.keys(obsRow).join(','));

const anonObs = await fetch(`${URL_}/rest/v1/audit_events?select=id`, { headers: { apikey: ANON, Authorization: `Bearer ${ANON}` } });
check('anon reads nothing from the audit ledger', anonObs.status >= 400 || n(await anonObs.json()) === 0, `status=${anonObs.status}`);

export default summary('P2 audit populations');
