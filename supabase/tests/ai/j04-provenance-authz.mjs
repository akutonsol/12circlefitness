// J-04 — Decision provenance and subject scoping.
//
// A decision trace is the audit record for a training decision made about a
// person's body. Two questions: does it record enough to replay the decision,
// and can only the right people read it?
import { mark, signIn, rest, rpc, section, characterize, invariant, summary } from './lib.mjs';

const _from = mark();

const victim   = await signIn('victim');
const attacker = await signIn('attacker');
const coach    = await signIn('coach');
const admin    = await signIn('admin');

section('J-04A  who can read a decision trace');
{
  // The policy (089) is: subject, creator, OR any account whose role is
  // admin / content_manager / coach. That last arm is not scoped to the coach's
  // own clients — unlike every other engine-output table, which all check the
  // owning program or an active relationship.
  const rel = await rest(coach, 'coach_client_relationships?select=coach_id,client_id,status');
  const relCount = Array.isArray(rel.body) ? rel.body.length : -1;
  invariant('the probe coach has no client relationships to justify access',
    relCount === 0, `${relCount} relationship row(s) visible`);

  const asCoach = await rest(coach, 'decision_traces?select=id,subject_id');
  const subjects = Array.isArray(asCoach.body)
    ? [...new Set(asCoach.body.map(r => r.subject_id))] : [];
  characterize('F-J-12  an unrelated coach reads every member\'s decision traces',
    subjects.length > 1 || (Array.isArray(asCoach.body) && asCoach.body.length > 0 && relCount === 0),
    `${Array.isArray(asCoach.body) ? asCoach.body.length : 0} trace(s) across ` +
    `${subjects.length} subject(s), with zero relationships — the role arm of the ` +
    'SELECT policy is unscoped');

  const asClient = await rest(attacker, 'decision_traces?select=id,subject_id');
  invariant('an unrelated CLIENT still reads nothing',
    Array.isArray(asClient.body) && asClient.body.length === 0,
    `${Array.isArray(asClient.body) ? asClient.body.length : asClient.status} row(s)`);
}

section('J-04B  what a decision trace actually records');
{
  const traces = await rest(admin, 'decision_traces?select=id,subject_id,created_by,engine_version,rules_version,scoring_version,graph_version,context,rules_triggered,explanation_client,explain_model&order=created_at.desc&limit=25');
  const rows = Array.isArray(traces.body) ? traces.body : [];
  invariant('traces are readable for audit', traces.status < 300, `HTTP ${traces.status}`);

  if (rows.length) {
    invariant('every trace carries the four engine version stamps',
      rows.every(r => r.engine_version && r.rules_version && r.scoring_version && r.graph_version),
      `e.g. ${rows[0].engine_version}/${rows[0].rules_version}/${rows[0].scoring_version}/${rows[0].graph_version}`);

    invariant('every trace names a subject and a creator',
      rows.every(r => r.subject_id && r.created_by), `${rows.length} row(s) checked`);

    // A trace is replayable only if it records the inputs the decision was made
    // from. `context` is whatever the caller passed — nothing snapshots the
    // member's real goal, equipment, recovery or injuries at decision time.
    const noInjuries = rows.filter(r => !Object.keys(r.context ?? {}).includes('injuries'));
    characterize('F-J-13  the recorded context is not an input snapshot',
      noInjuries.length === rows.length,
      `${noInjuries.length}/${rows.length} traces record no injuries at all; ` +
      `example context = ${JSON.stringify(rows[0].context)} — the decision cannot be replayed ` +
      'and there is no record of what safety state the member was in');

    characterize('F-J-14  no trace records a model identifier or an AI contribution',
      rows.every(r => !r.explain_model && !r.explanation_client),
      'explain_model and explanation_client are null on every row — the AI half of ' +
      'the pipeline leaves no provenance, and explain-decision is the only writer');
  }

  const analytics = await rpc(admin, 'decision_analytics');
  if (analytics.status < 300) {
    characterize('F-J-08  recorded decisions triggered no rule and rejected nothing',
      analytics.body?.most_triggered_rule === null && analytics.body?.most_rejected_exercise === null,
      `total_generations=${analytics.body?.total_generations}, ` +
      `most_triggered_rule=${analytics.body?.most_triggered_rule}, ` +
      `most_rejected_exercise=${analytics.body?.most_rejected_exercise}, ` +
      `avg_recovery=${analytics.body?.avg_recovery} — every persisted decision is an empty one`);
  }
}

section('J-04C  subject-scoped engine RPCs');
{
  // Migration 116 wrapped each subject/program-scoped engine function in a
  // can_act_for / can_act_on_program guard. Migration 119 then CREATE OR
  // REPLACEd one of them by its public name, which replaced the wrapper.
  // 116's own comment predicted exactly this; 122 restored the search_path and
  // grant halves of the 119 escape but not the guard.
  const program = (await rest(admin, 'workout_programs?select=id,coach_id&coach_id=not.is.null&limit=1')).body?.[0];
  invariant('a program owned by someone else exists to probe', !!program, program?.id ?? 'none');

  if (program) {
    // Week 99 is not in any plan, so the engine aborts before its DELETE. The
    // probe is therefore non-destructive and still proves how far the caller got.
    const guarded = ['evaluate_week', 'regenerate_program'];
    for (const f of guarded) {
      const r = await rpc(attacker, f, { p_program_id: program.id, p_week: 99 });
      invariant(`${f} refuses an unrelated caller`,
        r.status === 403 || r.body?.code === '42501',
        `HTTP ${r.status} ${r.body?.message ?? ''}`);
    }

    const m = await rpc(attacker, 'materialize_program_week',
      { p_program_id: program.id, p_week: 99, p_context: { size: 3 } });
    characterize('F-J-01  materialize_program_week lost its can_act_on_program guard',
      !(m.status === 403 || m.body?.code === '42501'),
      `HTTP ${m.status} ${m.body?.code ?? ''} "${m.body?.message ?? ''}" — the caller reached ` +
      'the engine body against another coach\'s program. With a real week number it would ' +
      'have DELETEd and rewritten that week\'s program_workouts.');
  }

  const forVictim = await rpc(attacker, 'generate_workout',
    { p_context: { size: 2 }, p_subject: (await rest(admin, 'decision_traces?select=subject_id&limit=1')).body?.[0]?.subject_id });
  invariant('generate_workout still refuses to forge provenance against another subject',
    forVictim.status === 403 || forVictim.body?.code === '42501',
    `HTTP ${forVictim.status} ${forVictim.body?.message ?? ''}`);
}

export default summary('J-04 provenance & scoping', _from);
