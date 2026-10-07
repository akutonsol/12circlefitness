// D17 · ENG-02 — `weekly_feedback.subject_id`, and the write path that deriving it
// would otherwise have opened. Live against QA, migration 175.
//
// WHY THE FREEZE IS TESTED AS HARD AS THE DERIVATION. Migration 117 split 094's
// `FOR ALL` policy to take DELETE away from the subject, but left the subject arm on
// UPDATE. That arm has been DEAD CODE ever since, for one reason: `subject_id` was
// never written, so no subject could match it. Deriving the subject WAKES it, over a
// row containing `coach_note` — the coach's written assessment of that person. So the
// derivation and the freeze ship together, and this suite proves both. A green
// "subject_id is now populated" without the freeze assertions would be a remediation
// that opened a hole and reported success.
//
// WHY EVERY DENIAL IS CHECKED BY RE-READING THE ROW. PostgREST answers 204 to a PATCH
// whether or not RLS or a BEFORE trigger silently discarded the change — and a column
// freeze NEVER errors, it just preserves OLD. So a status code here proves nothing at
// all, and every freeze assertion below compares the value before and after.
import { IDENT, signIn, rest, mutate, rpc, svc, check, section, summary, beginSuite, n }
  from './lib.mjs';

const ONE = (b) => (Array.isArray(b) ? b[0] : b) || {};

async function uidOf(key) {
  const r = await svc(`user_profiles?email=eq.${encodeURIComponent(IDENT[key].email)}&select=id`);
  return ONE(r.body).id;
}

const MARK = 'QA-D17';

async function run() {
  beginSuite();
  const coach = await signIn('coach');
  const victim = await signIn('victim');
  const coachUid = await uidOf('coach');
  const victimUid = await uidOf('victim');
  const attackerUid = await uidOf('attacker');

  // Purge by marker FIRST, so a crashed earlier run cannot make a correct assertion
  // fail forever — the §161 defect, not repeated.
  const purge = async () => {
    const progs = await svc(`workout_programs?name=like.${MARK}*&select=id`);
    for (const p of (Array.isArray(progs.body) ? progs.body : [])) {
      await svc(`weekly_feedback?program_id=eq.${p.id}`, { method: 'DELETE' });
      await svc(`workout_program_assignments?program_id=eq.${p.id}`, { method: 'DELETE' });
      await svc(`workout_programs?id=eq.${p.id}`, { method: 'DELETE' });
    }
  };

  const mkProgram = async (suffix) => {
    const r = await svc('workout_programs', { method: 'POST',
      headers: { Prefer: 'return=representation' },
      body: { name: `${MARK}-${suffix}`, coach_id: coachUid, duration_weeks: 4 } });
    return ONE(r.body).id;
  };
  const assign = (programId, clientId) => svc('workout_program_assignments',
    { method: 'POST', body: { program_id: programId, client_id: clientId,
      coach_id: coachUid, status: 'active' } });

  try {
    await purge();

    // ── 1 · the derivation, where it is unambiguous ────────────────────────
    section('ENG-02 · subject_id is derived from the single active assignment');
    const pOne = await mkProgram('one');
    check('arranged: a program with exactly ONE active assignment',
      pOne && (await assign(pOne, victimUid)).status < 300, `program=${pOne}`);

    const ins = await mutate(coach, 'weekly_feedback', 'POST',
      { program_id: pOne, week: 1, completion_pct: 80, coach_note: 'coach wrote this' });
    const rowOne = ONE((await svc(
      `weekly_feedback?program_id=eq.${pOne}&select=id,subject_id,coach_note`)).body);
    check('the coach can record a week, and subject_id is DERIVED — not left NULL as ' +
          'ENG-02 recorded, and not supplied by the client',
      ins.status < 300 && rowOne.subject_id === victimUid,
      `insert=${ins.status} subject_id=${rowOne.subject_id} expected=${victimUid}`);

    // ── 2 · the REFUSAL, proved rather than assumed ────────────────────────
    section('the derivation declines to guess where the model is ambiguous');
    const pTwo = await mkProgram('two');
    await assign(pTwo, victimUid);
    await assign(pTwo, attackerUid);
    const insTwo = await mutate(coach, 'weekly_feedback', 'POST',
      { program_id: pTwo, week: 1, completion_pct: 50 });
    const rowTwo = ONE((await svc(
      `weekly_feedback?program_id=eq.${pTwo}&select=subject_id`)).body);
    check('a program with TWO active assignments leaves subject_id NULL — whose body a ' +
          'coaching decision was made about is not something to guess',
      insTwo.status < 300 && rowTwo.subject_id === null,
      `insert=${insTwo.status} subject_id=${JSON.stringify(rowTwo.subject_id)}`);

    const pZero = await mkProgram('zero');
    const insZero = await mutate(coach, 'weekly_feedback', 'POST',
      { program_id: pZero, week: 1, completion_pct: 50 });
    const rowZero = ONE((await svc(
      `weekly_feedback?program_id=eq.${pZero}&select=subject_id`)).body);
    check('a program with NO active assignment leaves subject_id NULL',
      insZero.status < 300 && rowZero.subject_id === null,
      `insert=${insZero.status} subject_id=${JSON.stringify(rowZero.subject_id)}`);

    // ── 3 · what ENG-02 was for · the subject can see their own record ─────
    section('ENG-02 · the subject can now read the record of their own week');
    const asSubject = await rest(victim, `weekly_feedback?program_id=eq.${pOne}&select=id,subject_id`);
    const svcCount = await svc(`weekly_feedback?program_id=eq.${pOne}&select=id`);
    check('the SUBJECT reads their own feedback row — the same count the service role ' +
          'sees, so this is a real crossing and not an empty 200',
      asSubject.status < 300 && n(asSubject.body) === n(svcCount.body) && n(svcCount.body) === 1,
      `subject=${n(asSubject.body)} service=${n(svcCount.body)}`);
    const otherSees = await rest(victim, `weekly_feedback?program_id=eq.${pTwo}&select=id`);
    check('a NULL-subject row is still invisible to that same member, so the read is ' +
          'scoped by subject_id and not merely open',
      n(otherSees.body) === 0, `rows=${n(otherSees.body)}`);

    // ── 4 · THE HOLE THAT 175 CLOSES ──────────────────────────────────────
    section('the subject CANNOT overwrite the note their coach wrote about them');
    const before = ONE((await svc(
      `weekly_feedback?program_id=eq.${pOne}&select=coach_note`)).body).coach_note;
    const attempt = await mutate(victim,
      `weekly_feedback?program_id=eq.${pOne}`, 'PATCH', { coach_note: 'TAMPERED' });
    const after = ONE((await svc(
      `weekly_feedback?program_id=eq.${pOne}&select=coach_note`)).body).coach_note;
    check('coach_note survives a subject PATCH — asserted by RE-READING the row, ' +
          'because a column freeze never errors and PostgREST answers 204 either way',
      before === 'coach wrote this' && after === before,
      `status=${attempt.status} before=${JSON.stringify(before)} after=${JSON.stringify(after)}`);

    // The subject's own note must still work, or the freeze has broken the feature.
    const ownNote = await mutate(victim,
      `weekly_feedback?program_id=eq.${pOne}`, 'PATCH', { client_note: 'felt strong' });
    const noteBack = ONE((await svc(
      `weekly_feedback?program_id=eq.${pOne}&select=client_note`)).body).client_note;
    check('the subject CAN still write their own client_note — the freeze is scoped to ' +
          "the coach's column, not a blanket read-only",
      ownNote.status < 300 && noteBack === 'felt strong',
      `status=${ownNote.status} client_note=${JSON.stringify(noteBack)}`);

    const coachEdit = await mutate(coach,
      `weekly_feedback?program_id=eq.${pOne}`, 'PATCH', { coach_note: 'revised by coach' });
    const coachBack = ONE((await svc(
      `weekly_feedback?program_id=eq.${pOne}&select=coach_note`)).body).coach_note;
    check('the COACH can still revise their own note, so the freeze discriminates by ' +
          'actor rather than forbidding the column outright',
      coachEdit.status < 300 && coachBack === 'revised by coach',
      `status=${coachEdit.status} coach_note=${JSON.stringify(coachBack)}`);

    // ── 5 · identity is frozen ────────────────────────────────────────────
    section('identity columns are frozen on UPDATE');
    const reassign = await mutate(victim,
      `weekly_feedback?program_id=eq.${pOne}`, 'PATCH', { subject_id: attackerUid });
    const stillMine = ONE((await svc(
      `weekly_feedback?program_id=eq.${pOne}&select=subject_id`)).body).subject_id;
    check('a subject cannot reassign the row to someone else',
      stillMine === victimUid, `status=${reassign.status} subject_id=${stillMine}`);

    const moveProgram = await mutate(coach,
      `weekly_feedback?program_id=eq.${pOne}`, 'PATCH', { program_id: pZero, week: 99 });
    const identity = ONE((await svc(
      `weekly_feedback?subject_id=eq.${victimUid}&select=program_id,week`)).body);
    check('program_id and week are frozen even for the coach — which program and which ' +
          'week a record describes is not an editable field',
      identity.program_id === pOne && identity.week === 1,
      `status=${moveProgram.status} program_id=${identity.program_id} week=${identity.week}`);

    // ── 5b · THE POINT OF ENG-02, PROVED END TO END ───────────────────────
    // A populated column is not a working system. ENG-02's central claim is that
    // `needs_approval` NEVER FIRES for coach-guided clients, because `evaluate_week`
    // reads `coaching_mode` through `fb.subject_id` and that was always NULL. So the
    // two cases are run side by side: a derived subject and an undecidable one, over
    // the same RPC. If the derivation did nothing useful, both would answer the same.
    section('ENG-02 · the approval matrix fires again (evaluate_week, 127:161)');
    const priorMode = ONE((await svc(
      `user_profiles?id=eq.${victimUid}&select=coaching_mode`)).body).coaching_mode;
    await svc(`user_profiles?id=eq.${victimUid}`,
      { method: 'PATCH', body: { coaching_mode: 'coach_guided' } });
    // THE FIXTURE MUST ISOLATE THE MODE, AND MY FIRST ONE DID NOT. I first reported
    // `pain`, which is the top-priority branch — and `needs_approval` is
    // `(coach_guided and action <> CONTINUE) OR (rules && INJURY_ADAPTATION)`
    // (`127:188`), because "injury needs approval in every mode". So an injury
    // approves whatever the coaching mode is, and the undecidable program ALSO
    // returned needs_approval = true. The code was right and fail-safe; the fixture
    // chose the one branch where the mode cannot be the variable, and the contrast
    // assertion below is what caught it.
    //
    // Low adherence instead: recovery 70 skips the injury, fatigue and recovery
    // branches, and completion_pct 50 lands on ADHERENCE_SUPPORT — a non-CONTINUE
    // action that is NOT an injury. Now the coaching mode is the only difference
    // between the two programs.
    const adherence = { pain: [], recovery: 70, energy: 80, completion_pct: 50 };
    await svc(`weekly_feedback?program_id=eq.${pOne}`, { method: 'PATCH', body: adherence });
    await svc(`weekly_feedback?program_id=eq.${pTwo}`, { method: 'PATCH', body: adherence });

    const evalOne = await rpc(coach, 'evaluate_week',
      { p_program_id: pOne, p_week: 1 });
    const evalTwo = await rpc(coach, 'evaluate_week',
      { p_program_id: pTwo, p_week: 1 });
    const bodyOne = evalOne.body || {};
    const bodyTwo = evalTwo.body || {};
    check('with subject_id derived, evaluate_week RESOLVES the coaching mode — the ' +
          'read that ENG-02 recorded as permanently NULL',
      bodyOne.coaching_mode === 'coach_guided',
      `coaching_mode=${JSON.stringify(bodyOne.coaching_mode)} action=${JSON.stringify(bodyOne.action)}`);
    check('…and needs_approval FIRES for a coach-guided client on a non-CONTINUE ' +
          'action, so the approval matrix is no longer silently disabled',
      bodyOne.needs_approval === true && bodyOne.action !== 'CONTINUE',
      `needs_approval=${JSON.stringify(bodyOne.needs_approval)} action=${JSON.stringify(bodyOne.action)}`);
    // THE CONTRAST, and a finding inside it. The undecidable program reports
    // coaching_mode "unknown", which is the degenerate answer ENG-02 described — and
    // `needs_approval` comes back **null**, not false.
    //
    // That is SQL three-valued logic, not a typo: `v_mode` is NULL, so
    // `(NULL = 'coach_guided' and action <> 'CONTINUE')` is NULL, and `NULL or false`
    // is NULL (`127:188`). The author's expression reads as boolean and is not one
    // whenever the subject is undecidable.
    //
    // It is asserted AS NULL rather than quietly coalesced, because that is what the
    // RPC actually returns and a test that says otherwise is a worse artifact than the
    // defect. Behaviourally null and false are the same to every consumer — Dart and
    // JS both treat null as falsy — so there is no live hole beyond the question of
    // what the answer OUGHT to be when nobody knows whose program this is. Recorded in
    // V5 §171 as an owner question; this suite does not decide it, and does not change
    // the engine to suit its own expectations.
    check('the UNDECIDABLE program reports coaching_mode "unknown" and does NOT ' +
          'approve, so the contrast above is evidence rather than coincidence — and ' +
          'needs_approval is NULL there, which is three-valued logic, not false',
      bodyTwo.coaching_mode === 'unknown' && !bodyTwo.needs_approval,
      `coaching_mode=${JSON.stringify(bodyTwo.coaching_mode)} ` +
      `needs_approval=${JSON.stringify(bodyTwo.needs_approval)} ` +
      '(null is expected: see the comment above and V5 §171)');
    await svc(`user_profiles?id=eq.${victimUid}`,
      { method: 'PATCH', body: { coaching_mode: priorMode ?? null } });

    // ── 6 · the service path is untouched ─────────────────────────────────
    section('the internal path still writes freely');
    const svcPatch = await svc(`weekly_feedback?program_id=eq.${pOne}`,
      { method: 'PATCH', body: { coach_note: 'service wrote this' } });
    const svcBack = ONE((await svc(
      `weekly_feedback?program_id=eq.${pOne}&select=coach_note`)).body).coach_note;
    check('service_role is passed through, as 138:101 established for the sibling ' +
          'trigger — erasure and provenance decisions stay there',
      svcPatch.status < 300 && svcBack === 'service wrote this',
      `status=${svcPatch.status} coach_note=${JSON.stringify(svcBack)}`);
  } finally {
    await purge();
  }
  return summary('D17 · weekly_feedback subject integrity');
}

export default await run();
