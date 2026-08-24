import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/workout_log_model.dart';
import '../data/models/workout_model.dart';
import '../data/models/exercise_model.dart';
import '../data/workout_service.dart';
import '../data/workout_session_store.dart';
import '../domain/workout_provider.dart';
import '../domain/workout_restoration.dart';
import '../domain/workout_session_manager.dart';
import 'widgets/set_tracker_row.dart';
import 'widgets/rest_timer_widget.dart';
import 'widgets/exercise_guide_sheet.dart';
import '../../exercise_database/data/custom_exercise_service.dart';
import '../../exercise_database/data/exercise_database_service.dart';
import '../../../core/utils/rest_alarm.dart';
import '../../coach/data/score_service.dart';
import '../../scoring/data/score_engine.dart';
import '../../auth/domain/auth_provider.dart';

const _bg       = Color(0xFF030303);
const _card     = Color(0xFF0E0B16);
const _border   = Color(0xFF1A1020);
const _primary  = Color(0xFFDDB7FF);
const _brand    = Color(0xFFA855F7);
const _white    = Colors.white;
const _muted    = Color(0xFFCFC2D6);
const _tertiary = Color(0xFF6FFBBE);
const _error    = Color(0xFFFFB4AB);
const _amber    = Color(0xFFFFD580);

// ── Superset / Circuit group helper ──────────────────────────────────────────
class _ExGroup {
  final List<int> indices;
  final List<WorkoutExercise> items;
  const _ExGroup(this.indices, this.items);
  bool get isCircuit  => items.isNotEmpty && items.first.isCircuit;
  bool get isSuperset => !isCircuit && items.length > 1;
  String get supersetLabel => items.first.supersetGroup ?? 'A';
  int get circuitRounds => items.first.circuitRounds;
}

List<_ExGroup> _buildGroups(List<WorkoutExercise> exercises) {
  final groups = <_ExGroup>[];
  var i = 0;
  while (i < exercises.length) {
    final e = exercises[i];
    if (e.isCircuit && e.circuitGroup != null) {
      final idxs = [i];
      final items = [e];
      while (i + 1 < exercises.length &&
          exercises[i + 1].isCircuit &&
          exercises[i + 1].circuitGroup == e.circuitGroup) {
        i++;
        idxs.add(i);
        items.add(exercises[i]);
      }
      groups.add(_ExGroup(idxs, items));
    } else if (e.isSuperset && e.supersetGroup != null) {
      final idxs = [i];
      final items = [e];
      while (i + 1 < exercises.length &&
          exercises[i + 1].isSuperset &&
          exercises[i + 1].supersetGroup == e.supersetGroup) {
        i++;
        idxs.add(i);
        items.add(exercises[i]);
      }
      groups.add(_ExGroup(idxs, items));
    } else {
      groups.add(_ExGroup([i], [e]));
    }
    i++;
  }
  return groups;
}

/// Route entry for the Workout Zone.
///
/// Its only job is hydration. In-memory state does not survive a browser
/// refresh, so on a cold start there is no selected workout — and the screen
/// used to read that as "nothing to do" and offer Browse Workouts to a client
/// who was mid-session. The active session has to be rebuilt from storage
/// before that question can be answered, and until it is, this shows a
/// restoring state rather than an empty one.
///
/// Three distinct outcomes, never conflated:
///   * still restoring     → "Restoring your workout…"
///   * genuinely no session → the empty state
///   * a session that could not be rebuilt → a recovery state with a retry;
///     the session row is untouched, so nothing is discarded.
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A workout already in memory (started, or resumed from a Resume card) is
    // authoritative — the database has nothing to add.
    final workout = ref.watch(selectedWorkoutProvider);
    if (workout != null) return const _ActiveWorkoutView();

    final restoration = ref.watch(activeWorkoutRestorationProvider);
    return restoration.when(
      loading: () => const _RestoringWorkoutView(),
      error: (_, __) => _RestoreFailedView(
        onRetry: () => ref.invalidate(activeWorkoutRestorationProvider)),
      // Restoring hydrates `selectedWorkoutProvider`, so a restored session
      // lands in the Zone on the very next build.
      data: (restored) => restored == null
          ? const _NoActiveWorkoutView()
          : const _ActiveWorkoutView(),
    );
  }
}

/// The Workout Zone proper, entered only once a workout is resolved.
class _ActiveWorkoutView extends ConsumerStatefulWidget {
  const _ActiveWorkoutView();
  @override
  ConsumerState<_ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends ConsumerState<_ActiveWorkoutView> {
  int _elapsedSeconds = 0;
  int _idleSeconds = 0; // accumulated rest-overrun (overtime) across the session
  int _overtimePenalties = 0; // recurring overtime deductions for the current rest
  Timer? _timer;
  bool _saving = false;
  final _workoutService = WorkoutService();
  final _scrollController = ScrollController();
  final _db = Supabase.instance.client;
  /// Resolved once in initState so dispose() can persist elapsed time without
  /// reaching for `ref` during teardown.
  late final WorkoutSessionManager _sessions;
  String? _sessionId;
  /// The activation in flight, shared by every caller so a session is never
  /// opened twice concurrently. Null when none is running.
  Future<WorkoutSessionRecord?>? _activation;
  /// Whether the warm-up question has been settled for this mount — either
  /// asked, or found already answered for the session.
  bool _warmupSettled = false;
  /// Per-exercise anchors, so a restored session can scroll to the exercise it
  /// stopped at instead of opening at exercise 1.
  final Map<int, GlobalKey> _exerciseAnchors = {};
  int? _pendingScrollTo;
  int _scrollAttempts = 0;
  /// The set the client is on, by [WorkoutSet.id]. Mirrored onto the session so
  /// a refresh restores the position rather than re-deriving one.
  String _currentSetId = '';
  // Per-exercise (by name) RPE-tracking flag from the library metadata.
  final Map<String, bool> _showRpe = {};

  bool _showRpeFor(String name) => _showRpe[name] ?? true;

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(workoutSessionManagerProvider);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
    _startSession();
    _loadExerciseMeta();
    // The warm-up prompt is raised by _startSession once the session is known:
    // it is the session that has (or hasn't) been warmed up, not the screen.
  }

  /// Reads per-exercise tracking flags from the library so the set tracker can
  /// hide RPE for exercises that don't support it.
  Future<void> _loadExerciseMeta() async {
    final workout = ref.read(selectedWorkoutProvider);
    if (workout == null) return;
    final svc = CustomExerciseService();
    final names = {for (final e in workout.exercises) e.exercise.name};
    for (final name in names) {
      final meta = await svc.metaForName(name);
      _showRpe[name] = meta.rpe;
    }
    if (mounted) setState(() {});
  }

  /// Raises the warm-up prompt only when this session hasn't answered it.
  ///
  /// The acknowledgement lives on the session (migration 105), not on the
  /// screen, so a browser refresh — or leaving the Zone and coming back —
  /// restores the answer instead of asking a client who is already three sets
  /// in. A null [session] means session activation failed and there is nothing
  /// to record against; the prompt still shows, because repeating a safety step
  /// is better than skipping one.
  void _promptWarmupIfNeeded(WorkoutSessionRecord? session) {
    if (_warmupSettled || !mounted) return;
    _warmupSettled = true;
    if (session != null && session.warmupAcknowledged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showWarmupDialog(session?.id);
    });
  }

  /// Records the client's answer against the session, so it survives a reload.
  Future<void> _acknowledgeWarmup(String? sessionId) async {
    if (sessionId == null) return;
    try {
      await _sessions.acknowledgeWarmup(sessionId);
    } catch (_) {}
    if (!mounted) return;
    ref.invalidate(activeSessionProvider);
    ref.invalidate(activeWorkoutRestorationProvider);
  }

  void _showWarmupDialog(String? sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_brand.withValues(alpha: 0.3), _primary.withValues(alpha: 0.15)])),
              child: const Icon(Icons.local_fire_department_rounded, color: _amber, size: 38)),
            const SizedBox(height: 18),
            const Text('Welcome to the Workout Zone',
              textAlign: TextAlign.center,
              style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'Before you load up — spend 5–10 minutes warming up. Get the blood '
              'flowing, mobilize your joints, and activate the muscles you\'re about '
              'to train. A good warm-up means stronger lifts and fewer injuries.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 14, height: 1.5)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dctx);
                  _acknowledgeWarmup(sessionId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand, foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('I\'m Warmed Up — Let\'s Go',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ]))),
          ]),
        ),
      ),
    );
  }

  /// Activates the session for the selected workout.
  ///
  /// All session identity decisions live in [WorkoutSessionManager]: this
  /// either resumes the session already open for this workout, or opens a new
  /// one and abandons any previously open session. Either way exactly one
  /// session is in progress afterwards, and it is the one this screen writes
  /// sets to.
  Future<void> _startSession() async {
    final workout = ref.read(selectedWorkoutProvider);
    if (workout == null) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final before = await _sessions.activeSession(uid);
      final session = await _activate(uid, workout);
      if (session == null) return;

      final isResume = before != null && before.id == session.id;

      if (isResume) {
        if (mounted) setState(() => _elapsedSeconds = session.elapsedSeconds);
        await _restoreLoggedSets(session.id, workout);
        // Land on the set they stopped at, not on exercise 1 / set 1.
        _resumeAtPosition(workout, session);
      } else {
        ScoreEngine().workoutStarted(workout.id); // +5
      }

      _promptWarmupIfNeeded(session);

      // Every Resume surface reads activeSessionProvider — refresh it now that
      // the active session has changed.
      if (mounted) ref.invalidate(activeSessionProvider);
    } catch (e) {
      // Activation failed, so the *previous* session is still the authoritative
      // one — the client is looking at this workout but the app is not running
      // it. Say so rather than failing silently: a silent failure here is what
      // left an older workout as the resume candidate while the Zone showed a
      // newer one.
      _toastSave('Could not start this workout: $e');
      // Session state is unknown, so the warm-up can't be looked up — ask.
      _promptWarmupIfNeeded(null);
    }
  }

  /// Activates the session for [workout], with at most one activation in
  /// flight at a time.
  ///
  /// Both entry points can run concurrently — `_startSession` from initState
  /// and `_ensureSession` from the first set the client confirms — and each
  /// reads the open sessions before writing. Run in parallel they both see the
  /// old session, both abandon it, and both insert; the second insert then
  /// violates `workout_sessions_one_active_per_user` and the workout is left
  /// with no session of its own. Sharing one future makes the second caller
  /// await the first's answer instead of racing it.
  Future<WorkoutSessionRecord?> _activate(String uid, Workout workout) {
    return _activation ??= _sessions
        .startWorkout(userId: uid, workout: workout)
        .then((session) {
      _sessionId = session.id;
      // Bind the in-memory set state to this session — switching workouts
      // clears it so the previous workout's sets can't leak into this one.
      ref.read(activeWorkoutProvider.notifier).beginSession(session.id);
      return session;
    }).whenComplete(() => _activation = null);
  }

  /// Puts previously logged sets back into the in-memory state.
  ///
  /// A failed read is surfaced rather than swallowed: silently resuming with no
  /// sets shows recorded work as outstanding and invites the client to redo it.
  Future<void> _restoreLoggedSets(String sessionId, Workout workout) async {
    try {
      final logs = await _workoutService.getSessionCompletedSets(sessionId);
      if (mounted && logs.isNotEmpty) {
        // Seated against this workout, so each row goes back on the set whose
        // id it recorded rather than onto whatever slot is next.
        ref.read(activeWorkoutProvider.notifier).restoreFromLogs(workout, logs);
      }
    } catch (e) {
      _toastSave('Could not restore your logged sets: $e');
    }
  }

  /// Scrolls a resumed workout to the set the client left off on.
  ///
  /// [resumePosition] answers by identity: the session's stored cursor when it
  /// still names an outstanding set, otherwise the first set with no completion
  /// recorded against its id. Either way the answer names a set, and the index
  /// is only used to decide how far to scroll.
  void _resumeAtPosition(Workout workout, WorkoutSessionRecord? session) {
    if (!mounted) return;
    final position = resumePosition(workout, ref.read(activeWorkoutProvider),
        cursorSetId: session?.currentSetId);
    if (position.isComplete) return;
    _currentSetId = position.setId;
    // Cards are rendered per group, so a resume inside a superset or circuit
    // scrolls to the group that holds the exercise.
    final anchor = _groupAnchorIndex(workout, position.exerciseIndex);
    if (anchor == 0) return; // already at the top of the list
    _pendingScrollTo = anchor;
    _scrollAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPending());
  }

  /// The index the exercise's card is anchored under: its own, or the first
  /// index of the superset/circuit group it belongs to.
  int _groupAnchorIndex(Workout workout, int exerciseIndex) {
    for (final group in _buildGroups(workout.exercises)) {
      if (group.indices.contains(exerciseIndex)) return group.indices.first;
    }
    return exerciseIndex;
  }

  void _scrollToPending() {
    final index = _pendingScrollTo;
    if (index == null || !mounted) return;
    final ctx = _exerciseAnchors[index]?.currentContext;
    if (ctx == null) {
      // The list hasn't laid out yet. Try a couple more frames, then give up
      // rather than spin — an un-scrolled list is a far smaller problem than a
      // callback that never stops rescheduling.
      if (_scrollAttempts++ >= 5) {
        _pendingScrollTo = null;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPending());
      return;
    }
    _pendingScrollTo = null;
    Scrollable.ensureVisible(ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.05);
  }

  /// Records the set the client is working on against the session.
  ///
  /// Identity only — the id of the set and of its exercise — so the stored
  /// cursor stays meaningful if the workout is later reordered or re-snapshot.
  /// Written on the first interaction with a set and when one is completed;
  /// unchanged positions are not re-written.
  void _markCurrentSet(WorkoutExercise we, WorkoutSet set) {
    if (_currentSetId == set.id) return;
    _currentSetId = set.id;
    _saveCursor(we.instanceId, set.id);
  }

  /// Moves the cursor past a just-completed set — forward first, so a client
  /// who started at a later exercise isn't sent back to a set they left open on
  /// purpose. [advancePosition] always names a real set, so the stored cursor
  /// stays resolvable.
  void _advanceCurrentSet(WorkoutExercise we, WorkoutSet set) {
    final workout = ref.read(selectedWorkoutProvider);
    if (workout == null) {
      _markCurrentSet(we, set);
      return;
    }
    final next =
        advancePosition(workout, ref.read(activeWorkoutProvider), set.id);
    _currentSetId = next.setId;
    _saveCursor(next.exerciseId, next.setId);
  }

  Future<void> _saveCursor(String exerciseId, String setId) async {
    final sid = _sessionId;
    if (sid == null || setId.isEmpty) return;
    try {
      await _sessions.saveCursor(
          sessionId: sid, exerciseId: exerciseId, setId: setId);
    } catch (_) {
      // A lost cursor write costs the client a scroll, not their data: the
      // restore falls back to the first outstanding set.
    }
  }

  /// Stable scroll anchor for an exercise, by its index in the workout.
  GlobalKey _anchorFor(int exerciseIndex) =>
      _exerciseAnchors.putIfAbsent(exerciseIndex, GlobalKey.new);

  /// Display unit from the user's preference ('lb' for imperial, 'kg' for metric).
  String get _unit {
    final pref =
        ref.read(currentUserProfileProvider).valueOrNull?['unit_preference'] as String?;
    return pref == 'metric' ? 'kg' : 'lb';
  }

  /// Returns the active session id, creating the session row on demand so set
  /// logs can't be silently dropped when the session insert was delayed/failed.
  Future<String?> _ensureSession() async {
    if (_sessionId != null) return _sessionId;
    final workout = ref.read(selectedWorkoutProvider);
    final uid = _db.auth.currentUser?.id;
    if (workout == null || uid == null) return null;
    // Joins the activation already started in initState rather than opening a
    // competing one.
    final session = await _activate(uid, workout);
    if (session == null) return null;
    if (mounted) ref.invalidate(activeSessionProvider);
    return _sessionId;
  }

  /// Persists a set (ensuring a session exists). Fire-and-forget so callers
  /// don't await across a widget-tree mutation. saveSetLog upserts, so this is
  /// safe to call repeatedly (on edit and on complete). Surfaces errors so a
  /// failed save is visible instead of silently dropped.
  Future<void> _persistSet(String exerciseName, String exerciseInstanceId,
      String? libraryExerciseId, String setId, int setNumber,
      String? tempo, int reps, double weightKg, double? rpe, String? notes,
      bool completed) async {
    try {
      final sid = await _ensureSession();
      if (sid == null) {
        _toastSave('No active workout session.');
        return;
      }
      await _workoutService.saveSetLog(
        sessionId: sid,
        exerciseName: exerciseName,
        exerciseInstanceId: exerciseInstanceId,
        libraryExerciseId: libraryExerciseId,
        setId: setId,
        setNumber: setNumber,
        reps: reps,
        weightKg: weightKg,
        rpe: rpe,
        notes: notes,
        tempo: tempo,
        completed: completed,
      );
    } catch (e) {
      _toastSave('Could not save set: $e');
    }
  }

  void _toastSave(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _error));
  }

  /// Heuristic: does this exercise use only bodyweight (no external load)?
  bool _isBodyweight(WorkoutExercise we) {
    final eq = we.exercise.equipment.toLowerCase();
    if (eq.contains('bodyweight') || eq.contains('body weight') || eq == 'none') return true;
    final n = we.exercise.name.toLowerCase();
    const kw = ['plank', 'push-up', 'push up', 'pushup', 'pull-up', 'pull up',
      'pullup', 'chin-up', 'dip', 'glute bridge', 'sit-up', 'situp', 'crunch',
      'mountain climber', 'burpee', 'inverted row', 'pike', 'air squat',
      'hollow', 'superman', 'bird dog', 'wall sit', 'hanging', 'leg raise'];
    return kw.any(n.contains);
  }

  /// Dismisses the rest/overtime alarm (the user is starting the next set).
  /// Banks any overtime as idle time, then clears the timer (which stops the
  /// siren via the widget's dispose).
  void _dismissRest() {
    final rt = ref.read(restTimerProvider);
    if (rt == null) return;
    final over = DateTime.now().difference(rt.end).inSeconds;
    if (over > 0) _idleSeconds += over;
    ref.read(restTimerProvider.notifier).state = null;
  }

  /// Caches entered values into the in-memory workout state so the row's fields
  /// reflect them across rebuilds (and survive navigation within the session).
  ///
  /// The notifier is the gate: it drops weight/reps/RPE aimed at a completed
  /// set. Returns whether anything was actually written, so an edit it refused
  /// isn't persisted either.
  bool _cacheSet(WorkoutExercise we, WorkoutSet set, int reps, double weightKg,
      double? rpe, String? notes) {
    return ref.read(activeWorkoutProvider.notifier).setSetData(set, {
      'reps': reps,
      'weight': weightKg,
      'rpe': rpe,
      'notes': notes,
    }, exerciseInstanceId: we.instanceId);
  }

  /// Writes a set to the database from the in-memory state rather than from
  /// the values a row reported.
  ///
  /// State is the authority on what a set holds — it has already rejected any
  /// edit to a completed set — so persisting from it means the recorded result
  /// is what reaches `workout_set_logs`, whatever a widget emitted.
  void _persistFromState(WorkoutExercise we, WorkoutSet set) {
    final data = ref.read(activeWorkoutProvider.notifier).setData(set.id);
    _persistSet(
      we.exercise.name,
      we.instanceId,
      we.exercise.id,
      set.id,
      set.setNumber,
      set.tempo,
      (data['reps'] as num?)?.toInt() ?? set.reps,
      // A set with no prescribed load logs 0 when the client entered nothing —
      // there is no other honest number — but the prescription itself stays
      // absent, so the field shows no target rather than "0".
      (data['weight'] as num?)?.toDouble() ?? set.weightKg ?? 0,
      (data['rpe'] as num?)?.toDouble(),
      data['notes'] as String?,
      data['completed'] == true,
    );
  }

  Future<void> _saveElapsed() async {
    final sid = _sessionId;
    if (sid == null) return;
    try {
      await _sessions.saveElapsed(sid, _elapsedSeconds);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _saveElapsed(); // persist elapsed time so resume can restore it
    super.dispose();
  }

  String get _elapsedTime {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _completeWorkout() async {
    final workout = ref.read(selectedWorkoutProvider);
    if (workout == null) return;

    _dismissRest(); // bank any in-progress overtime + silence the siren
    setState(() => _saving = true);
    _timer?.cancel();

    final log = WorkoutLog(
      workoutId: workout.id,
      workoutTitle: workout.title,
      durationMinutes: _elapsedSeconds ~/ 60,
      caloriesBurned: (_elapsedSeconds ~/ 60 * 8),
      category: workout.category,
      notes: '',
    );

    await _workoutService.logWorkout(log);

    if (_sessionId != null) {
      try {
        await _sessions.completeSession(
              sessionId: _sessionId!,
              durationSeconds: _elapsedSeconds,
              idleSeconds: _idleSeconds,
              caloriesBurned: log.caloriesBurned ?? 0,
            );
      } catch (_) {}
    }

    await ScoreService().addWorkoutPoints();
    await ScoreEngine().workoutCompleted(workout.id);
    ref.read(activeWorkoutProvider.notifier).reset();
    // The session id is spent for logging purposes, but the feedback sheet
    // still has to name the session it is rating, so hand it the captured id.
    final finishedSessionId = _sessionId;
    _sessionId = null;
    // The session is archived — stop offering it as resumable, and drop the
    // restored copy so a later cold start doesn't rebuild a finished workout.
    ref.invalidate(activeSessionProvider);
    ref.invalidate(activeWorkoutRestorationProvider);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _WorkoutCompleteDialog(
          title: workout.title,
          duration: _elapsedTime,
          calories: log.caloriesBurned ?? 0,
          idleSeconds: _idleSeconds,
          sessionId: finishedSessionId,
          // Both exits — Skip and Submit — come through here.
          onDone: () {
            Navigator.pop(context);
            _leaveFinishedWorkout();
            context.go('/home');
          },
        ),
      );
    } else {
      // Finish Early → Skip can pop this screen before the dialog is raised.
      // Clearing here too means a completed workout is never left selected.
      _leaveFinishedWorkout();
    }
    // Guarded: _completeWorkout awaits four network round-trips, and Finish
    // Early → Skip pops this screen while they are still in flight. An
    // unguarded setState there throws "setState() called after dispose()".
    if (mounted) setState(() => _saving = false);
  }

  /// Drops the finished workout from the selection.
  ///
  /// A completed workout that stays selected is still a workout "in memory",
  /// and the Zone treats in-memory as authoritative — so re-entering it
  /// skipped restoration and called startWorkout on the finished workout,
  /// opening a fresh in-progress session for it. That resurrected session then
  /// became the newest one and took over the Resume card. Clearing the
  /// selection is what makes completion final.
  void _leaveFinishedWorkout() {
    ref.read(selectedWorkoutProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(selectedWorkoutProvider);
    final activeData = ref.watch(activeWorkoutProvider);

    // Rest countdown is driven by a wall-clock end time in a provider, so it
    // survives navigating away and resumes at the right remaining time.
    final rest = ref.watch(restTimerProvider);

    // The shell only mounts this view with a workout resolved; if it is cleared
    // out from under us the shell takes over on the next build, so hold the
    // hydration state for the frame in between rather than flashing an empty one.
    if (workout == null) return const _RestoringWorkoutView();

    // Counted over the workout's own sets, by id: state left behind by an
    // exercise that has since been swapped out is not progress through the
    // workout the client is doing now.
    final completedSets = workout.exercises
        .expand((e) => e.sets)
        .where((s) => activeData[s.id]?['completed'] == true)
        .length;
    final totalSets = workout.exercises
        .fold(0, (sum, e) => sum + e.sets.length);
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    final groups = _buildGroups(workout.exercises);

    return Scaffold(
      backgroundColor: _bg,
      // Tapping empty space unfocuses the active field → its blur listener
      // persists the entered values (so "type and click away" saves on web).
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: Stack(children: [
        Column(children: [
          // ── Top bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(bottom: BorderSide(color: _border))),
            child: Row(children: [
              GestureDetector(
                onTap: () => _showEndDialog(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _error.withValues(alpha: 0.3))),
                  child: const Icon(Icons.close, color: _error, size: 18))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Workout Zone',
                    style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(workout.title,
                    style: TextStyle(color: _primary.withValues(alpha: 0.7), fontSize: 11)),
                ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _brand.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, color: _brand, size: 14),
                  const SizedBox(width: 5),
                  Text(_elapsedTime,
                    style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w700)),
                ])),
            ])),

          // ── Progress bar ──
          LinearProgressIndicator(
            value: progress,
            backgroundColor: _border,
            valueColor: const AlwaysStoppedAnimation<Color>(_brand),
            minHeight: 3),

          // ── Fixed rest banner (above the list so it never shifts content) ──
          // Keep the rest banner mounted through overtime (negative countdown +
          // siren + recurring penalty). Dismissed by starting the next set
          // (weight-field focus) or STOP — NOT by the clock reaching zero.
          if (rest != null)
            RestTimerWidget(
              key: ValueKey(rest.end),
              endTime: rest.end,
              totalSeconds: rest.total,
              onOvertime: () {
                _overtimePenalties = 1;
                ScoreEngine().idleTimePenalty(); // -5 the moment rest runs over
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('−5 points — rest overrun. Start your next set to '
                        'stop the drain!'),
                    backgroundColor: _error));
                }
              },
              // Keep draining points every interval they stay in overtime, until
              // they start the next set — capped so a forgotten timer can't zero
              // the whole score.
              onOvertimePenaltyTick: () {
                if (_overtimePenalties >= 8) return;
                _overtimePenalties++;
                ScoreEngine().idleTimePenalty();
              },
              onComplete: _dismissRest),

          // ── Exercise list ──
          Expanded(
            child: ListView(
              controller: _scrollController,
              key: const PageStorageKey('active_workout_list'),
              padding: const EdgeInsets.all(16),
              children: [
                // Progress summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(label: 'Sets Done', value: '$completedSets/$totalSets', color: _brand),
                      Container(width: 1, height: 30, color: _border),
                      _StatChip(label: 'Exercises', value: '${workout.exercises.length}', color: _primary),
                      Container(width: 1, height: 30, color: _border),
                      _StatChip(label: 'Est. Kcal', value: '${(_elapsedSeconds ~/ 60 * 8)}', color: _tertiary),
                    ])),

                // ── Today's coach adjustment (applied as load guidance) ──
                ref.watch(coachAdjustmentProvider).maybeWhen(
                  data: (adj) => adj == null ? const SizedBox.shrink() : _ActiveCoachBanner(adj: adj),
                  orElse: () => const SizedBox.shrink()),

                // ── Render groups (superset / circuit / solo) ──
                ...groups.map((group) {
                  final Widget card;
                  if (group.isCircuit) {
                    card = _buildCircuitGroup(group, activeData, workout);
                  } else if (group.isSuperset) {
                    card = _buildSupersetGroup(group, activeData, workout);
                  } else {
                    card = _buildExerciseCard(group.indices[0], group.items[0], activeData, workout);
                  }
                  // Anchored by the group's first exercise index, which is what
                  // the resume position names.
                  return KeyedSubtree(
                    key: _anchorFor(group.indices.first), child: card);
                }),

                const SizedBox(height: 80),
              ])),

          // ── Complete button ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(top: BorderSide(color: _border))),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _completeWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: completedSets == totalSets ? _brand : _brand.withValues(alpha: 0.6),
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
                child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(completedSets == totalSets ? Icons.check_circle : Icons.flag_outlined,
                        size: 18),
                      const SizedBox(width: 8),
                      Text(
                        completedSets == totalSets ? 'Complete Workout' : 'Finish Early ($completedSets/$totalSets sets)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ]))))
        ]),
        ]),
        ),
      ),
    );
  }

  // ── Single exercise card ──────────────────────────────────────────────────
  Widget _buildExerciseCard(
    int index,
    WorkoutExercise we,
    Map<String, Map<String, dynamic>> activeData,
    Workout workout,
  ) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _exerciseHeader(index, we),
        if (we.notes != null && we.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(we.notes!,
              style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 11, fontStyle: FontStyle.italic))),
        const SizedBox(height: 12),
        _columnHeaders(showRpe: _showRpeFor(we.exercise.name)),
        ..._buildSetRows(we, activeData),
        const SizedBox(height: 8),
      ]));
  }

  // ── Superset group ────────────────────────────────────────────────────────
  Widget _buildSupersetGroup(
    _ExGroup group,
    Map<String, Map<String, dynamic>> activeData,
    Workout workout,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber.withValues(alpha: 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Superset label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _amber.withValues(alpha: 0.4))),
              child: Row(children: [
                const Icon(Icons.swap_vert_rounded, color: _amber, size: 13),
                const SizedBox(width: 4),
                Text('SUPERSET ${group.supersetLabel.toUpperCase()}',
                  style: const TextStyle(color: _amber, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
              ])),
            const Spacer(),
            Text('${group.items.length} exercises',
              style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10)),
          ])),
        // Each exercise in the superset
        ...group.items.asMap().entries.map((e) {
          final i = e.key;
          final we = e.value;
      
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Icon(Icons.arrow_downward_rounded, color: _amber, size: 14),
                  const SizedBox(width: 6),
                  Text('Then:', style: TextStyle(color: _amber.withValues(alpha: 0.7), fontSize: 11)),
                ])),
            _exerciseHeader(group.indices[i], we),
            if (we.notes != null && we.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(we.notes!,
                  style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 11, fontStyle: FontStyle.italic))),
            const SizedBox(height: 10),
            _columnHeaders(),
            ..._buildSetRows(we, activeData),
            if (i < group.items.length - 1)
              Divider(color: _amber.withValues(alpha: 0.15), thickness: 1,
                indent: 16, endIndent: 16),
          ]);
        }),
        const SizedBox(height: 8),
      ]));
  }

  // ── Circuit group ─────────────────────────────────────────────────────────
  Widget _buildCircuitGroup(
    _ExGroup group,
    Map<String, Map<String, dynamic>> activeData,
    Workout workout,
  ) {
    const circuitColor = Color(0xFFA855F7); // brand purple
    return StatefulBuilder(builder: (ctx, setSB) {
      int currentRound = 1; // tracked locally via StatefulBuilder
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: circuitColor.withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Circuit header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: circuitColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: circuitColor.withValues(alpha: 0.4))),
                child: Row(children: [
                  const Icon(Icons.loop_rounded, color: circuitColor, size: 13),
                  const SizedBox(width: 4),
                  Text('CIRCUIT  •  ${group.circuitRounds} ROUNDS',
                    style: const TextStyle(color: circuitColor, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
                ])),
              const Spacer(),
              // Round counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: circuitColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  GestureDetector(
                    onTap: () { if (currentRound > 1) setSB(() => currentRound--); },
                    child: const Icon(Icons.remove_rounded, color: _muted, size: 16)),
                  const SizedBox(width: 6),
                  Text('Round $currentRound',
                    style: const TextStyle(color: _white, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () { if (currentRound < group.circuitRounds) setSB(() => currentRound++); },
                    child: const Icon(Icons.add_rounded, color: circuitColor, size: 16)),
                ])),
            ])),
          // Exercises in circuit
          ...group.items.asMap().entries.map((e) {
            final i = e.key;
            final we = e.value;
        
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.arrow_downward_rounded, color: circuitColor, size: 13),
                    const SizedBox(width: 4),
                    Text('Next:', style: TextStyle(color: circuitColor.withValues(alpha: 0.7), fontSize: 11)),
                  ])),
              _exerciseHeader(group.indices[i], we),
              if (we.notes != null && we.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(we.notes!, style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 11, fontStyle: FontStyle.italic))),
              const SizedBox(height: 10),
              _columnHeaders(),
              ..._buildSetRows(we, activeData),
              if (i < group.items.length - 1)
                Divider(color: circuitColor.withValues(alpha: 0.12), thickness: 1, indent: 16, endIndent: 16),
            ]);
          }),
          const SizedBox(height: 8),
        ]));
    });
  }

  Widget _exerciseHeader(int index, WorkoutExercise we) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: _brand.withValues(alpha: 0.3))),
          child: Center(
            child: Text('${index + 1}',
              style: const TextStyle(color: _brand, fontWeight: FontWeight.w800, fontSize: 13)))),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => showExerciseGuide(context, we.exercise.name),
            child: Row(children: [
              Flexible(
                child: Text(we.exercise.name,
                  style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              const _GuideIconPulse(),
            ]),
          )),
        GestureDetector(
          onTap: () => _showSwapSheet(index, we), // swap this exercise
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.swap_horizontal_circle_rounded, color: _primary.withValues(alpha: 0.8), size: 22))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999)),
          child: Text(we.exercise.muscleGroup,
            style: TextStyle(color: _primary.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600))),
      ]));
  }

  /// Correct swap recommendations from the built-in library — never a random
  /// cross-muscle grab. Prefers the exercise's own curated `alternatives`
  /// (the recommendations authored in the app); if the exercise isn't in the
  /// library, falls back to same-muscle-group matches. An empty/unknown muscle
  /// group returns nothing rather than "any exercise".
  List<Map<String, dynamic>> _librarySubstitutes(WorkoutExercise we) {
    final lib = ExerciseDatabaseService().getAllExercises();
    final selfName = we.exercise.name.trim().toLowerCase();

    // Index by lowercased name for detail lookups.
    final byName = {for (final e in lib) e.name.trim().toLowerCase(): e};
    final self = byName[selfName];

    Map<String, dynamic> row(dynamic e) => {
      'name': e.name, 'equipment': e.equipment, 'difficulty': e.difficulty,
      'muscle_group': e.muscleGroup, 'video_url': e.videoUrl,
    };

    // 1) Curated alternatives for this exercise — the recommended swaps.
    if (self != null && self.alternatives.isNotEmpty) {
      final out = <Map<String, dynamic>>[];
      for (final alt in self.alternatives) {
        final match = byName[alt.trim().toLowerCase()];
        out.add(match != null
            ? row(match)
            : {'name': alt, 'equipment': '', 'difficulty': '', 'muscle_group': self.muscleGroup});
      }
      if (out.isNotEmpty) return out;
    }

    // 2) Same-muscle-group fallback (resolve the group from the library by name).
    final mg = (self?.muscleGroup ?? we.exercise.muscleGroup).trim().toLowerCase();
    if (mg.isEmpty) return const [];
    final out = <Map<String, dynamic>>[];
    for (final e in lib) {
      if (e.muscleGroup.trim().toLowerCase() == mg &&
          e.name.trim().toLowerCase() != selfName) {
        out.add(row(e));
        if (out.length >= 12) break;
      }
    }
    return out;
  }

  /// Swap an exercise for a same-muscle substitute (keeps the set structure).
  Future<void> _showSwapSheet(int index, WorkoutExercise we) async {
    // Prefer the built-in library (reliable same-muscle matches); only if it has
    // nothing do we consult approved global custom exercises.
    var subs = _librarySubstitutes(we);
    if (subs.isEmpty) {
      subs = await CustomExerciseService()
          .getSubstitutes(we.exercise.name, we.exercise.muscleGroup);
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context, backgroundColor: _card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Swap “${we.exercise.name}”',
              style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Same muscle group · keeps your sets',
              style: TextStyle(color: _muted.withValues(alpha: 0.7), fontSize: 12)),
            const SizedBox(height: 12),
            if (subs.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No substitutes found.', style: TextStyle(color: _muted)))
            else
              // Scrollable so a long substitute list never overflows the sheet.
              Flexible(child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: subs.map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s['name']?.toString() ?? '', style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('${s['equipment'] ?? ''} · ${s['difficulty'] ?? ''}',
                    style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 11)),
                  trailing: const Icon(Icons.swap_horizontal_circle_rounded, color: _primary, size: 22),
                  onTap: () { Navigator.pop(ctx); _swapExercise(index, we, s); })).toList())),
          ])))));
  }

  /// Replaces one exercise instance with a substitute movement.
  ///
  /// A swap is a **new instance**, not an edit of the old one. [WorkoutExercise
  /// .replacedBy] mints a fresh instance id and fresh set ids, so:
  ///
  ///  * the new movement's sets start empty rather than inheriting the replaced
  ///    exercise's completion state (which the immutability rule would then
  ///    lock, against values the client never entered for it);
  ///  * the first set logged against it inserts under its own identity instead
  ///    of colliding with the row already written for the replaced set
  ///    (`uq_workout_set_logs_set_identity`, 23505);
  ///  * the replaced exercise's own logs are untouched — the client did that
  ///    work and it stays attributed to the movement they actually performed.
  ///
  /// Load is deliberately not carried over: the prescribed weight belongs to the
  /// movement being replaced. What carries is the structure — sets, reps, rest,
  /// tempo — which is what "keeps your sets" means to a client.
  Future<void> _swapExercise(
      int index, WorkoutExercise we, Map<String, dynamic> sub) async {
    final workout = ref.read(selectedWorkoutProvider);
    if (workout == null || index < 0 || index >= workout.exercises.length) return;
    final newEx = Exercise(
      id: sub['id']?.toString() ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: sub['name']?.toString() ?? we.exercise.name,
      category: we.exercise.category,
      muscleGroup: sub['muscle_group']?.toString() ?? we.exercise.muscleGroup,
      equipment: sub['equipment']?.toString() ?? we.exercise.equipment,
      difficulty: sub['difficulty']?.toString() ?? we.exercise.difficulty,
      description: '', instructions: const []);

    final updated = workout.replacingExerciseAt(
      index,
      we.replacedBy(newEx,
          instanceId: 'swap-${DateTime.now().microsecondsSinceEpoch}'),
    );
    ref.read(selectedWorkoutProvider.notifier).state = updated;

    // The cursor pointed into the exercise that is gone. Re-point it at the
    // replacement's first set so a refresh lands somewhere that exists.
    final replacement = updated.exercises[index];
    if (replacement.sets.isNotEmpty &&
        (_currentSetId == null || we.setById(_currentSetId!) != null)) {
      _currentSetId = replacement.sets.first.id;
      _saveCursor(replacement.instanceId, replacement.sets.first.id);
    }

    setState(() {});
    // The session's stored definition follows the swap, so a refresh restores
    // the workout the client is doing rather than the one they started. Awaited
    // and surfaced: a lost re-snapshot silently resurrects the replaced
    // exercise on the next reload, along with its set ids.
    final saved = await _resnapshotSession(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved
          ? 'Swapped to ${newEx.name}'
          : 'Swapped to ${newEx.name} — but the change could not be saved. '
              'Reloading will bring back ${we.exercise.name}.'),
      backgroundColor: saved ? null : _error));
  }

  /// Re-stores the session's workout snapshot after a mid-session change, so
  /// restoration rebuilds the same exercises in the same order. Returns whether
  /// the snapshot reached the database.
  Future<bool> _resnapshotSession(Workout workout) async {
    final sid = _sessionId;
    if (sid == null) return false;
    try {
      await _sessions.saveSnapshot(sid, workout);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _columnHeaders({bool showRpe = true}) {
    final hStyle = TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10,
      fontWeight: FontWeight.w600, letterSpacing: 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        SizedBox(width: 36,
          child: Text('SET', style: hStyle)),
        Expanded(child: Text('WEIGHT (${_unit.toUpperCase()})', textAlign: TextAlign.center, style: hStyle)),
        const SizedBox(width: 8),
        Expanded(child: Text('REPS', textAlign: TextAlign.center, style: hStyle)),
        if (showRpe) ...[
          const SizedBox(width: 8),
          Expanded(child: Text('RPE', textAlign: TextAlign.center, style: hStyle)),
        ],
        const SizedBox(width: 74), // notes icon (28) + gap (6) + check (32) + gap (8)
      ]));
  }

  List<Widget> _buildSetRows(
    WorkoutExercise we,
    Map<String, Map<String, dynamic>> activeData,
  ) {
    return we.sets.map((set) {
      // By id, never by position: a row shows the state recorded against this
      // set, whatever order the sets are in and however many of them loaded.
      final setData = activeData[set.id] ?? const <String, dynamic>{};
      final isCompleted = setData['completed'] == true;

      return SetTrackerRow(
        // The set's own identity is the widget's identity too, so Flutter never
        // recycles one set's field state onto another.
        key: ValueKey(set.id),
        setNumber: set.setNumber,
        targetReps: set.reps,
        targetWeight: set.weightKg,
        completed: isCompleted,
        tempo: set.tempo,
        unit: _unit,
        // Restore previously-logged values so they reappear on return.
        savedWeightKg: (setData['weight'] as num?)?.toDouble(),
        savedReps: (setData['reps'] as num?)?.toInt(),
        savedRpe: (setData['rpe'] as num?)?.toDouble(),
        savedNotes: setData['notes'] as String?,
        isBodyweight: _isBodyweight(we),
        showRpe: _showRpeFor(we.exercise.name),
        onWeightFocus: _dismissRest,
        // Persist field edits (on blur / enter) even if the set isn't completed.
        // A completed set only gets here for its note; the notifier drops the
        // rest, and a refused edit isn't written to the database either.
        onChanged: (reps, weight, rpe, notes) {
          _markCurrentSet(we, set);
          if (_cacheSet(we, set, reps, weight, rpe, notes)) {
            _persistFromState(we, set);
          }
        },
        onCompleted: (reps, weight, rpe, notes) {
          // Completion is one-way: the notifier records the final values and
          // refuses an already-completed set, so this can't reopen or rewrite
          // one. Corrections go through onEditCompleted instead.
          final justCompleted = ref.read(activeWorkoutProvider.notifier).completeSet(
            set,
            {'reps': reps, 'weight': weight, 'rpe': rpe, 'notes': notes},
            we.instanceId);
          if (!justCompleted) return;
          _advanceCurrentSet(we, set);
          if (set.restSeconds != null) {
            // Unlock audio now (this is a user gesture) so the later beep/voice
            // aren't blocked, then start the wall-clock rest countdown.
            primeRestAudio();
            _overtimePenalties = 0; // fresh overtime budget for this rest
            ref.read(restTimerProvider.notifier).state = RestTimerState(
              DateTime.now().add(Duration(seconds: set.restSeconds!)),
              set.restSeconds!);
          }
          // Persist the values as recorded (fire-and-forget).
          _persistFromState(we, set);
        },
        onEditCompleted: isCompleted
            ? () => _editCompletedSet(we, set)
            : null);
    }).toList();
  }

  /// Deliberate correction of an already-completed set.
  ///
  /// Completed values are locked everywhere else, so this is the only path
  /// that can change them. It names the set as already recorded, needs an
  /// explicit confirmation, and leaves completion untouched — a correction
  /// fixes what was logged, it doesn't reopen the set.
  Future<void> _editCompletedSet(WorkoutExercise we, WorkoutSet set) async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final data = notifier.setData(set.id);
    final showRpe = _showRpeFor(we.exercise.name);

    final weightKg = (data['weight'] as num?)?.toDouble() ?? 0;
    final weightCtl = TextEditingController(
        text: weightKg > 0 ? _fmtNum(_toDisplayWeight(weightKg)) : '');
    final repsCtl = TextEditingController(
        text: (data['reps'] as num?)?.toInt().toString() ?? '');
    final rpeCtl = TextEditingController(
        text: data['rpe'] != null ? _fmtNum((data['rpe'] as num).toDouble()) : '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6)),
            child: const Text('COMPLETED',
              style: TextStyle(color: _tertiary, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 1))),
          const SizedBox(height: 10),
          Text('Edit Set ${set.setNumber} · ${we.exercise.name}',
            style: const TextStyle(
              color: _white, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'This set is already recorded in your workout history. Correcting '
            'it updates the logged result — it stays completed either way.',
            style: TextStyle(color: _muted.withValues(alpha: 0.75), fontSize: 13, height: 1.4)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _correctionField(weightCtl, 'WEIGHT (${_unit.toUpperCase()})')),
            const SizedBox(width: 10),
            Expanded(child: _correctionField(repsCtl, 'REPS')),
            if (showRpe) ...[
              const SizedBox(width: 10),
              Expanded(child: _correctionField(rpeCtl, 'RPE')),
            ],
          ]),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Save Correction',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w700))),
        ]));

    final newWeight = double.tryParse(weightCtl.text.trim());
    final newReps = int.tryParse(repsCtl.text.trim());
    final rpeText = rpeCtl.text.trim();
    weightCtl.dispose();
    repsCtl.dispose();
    rpeCtl.dispose();
    if (confirmed != true) return;

    final applied = notifier.applyCorrection(
      set,
      exerciseInstanceId: we.instanceId,
      reps: newReps,
      weight: newWeight != null ? _toKgWeight(newWeight) : null,
      rpe: showRpe ? double.tryParse(rpeText) : null,
      clearRpe: showRpe && rpeText.isEmpty,
    );
    if (!applied) return;
    _persistFromState(we, set);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Set ${set.setNumber} corrected')));
    }
  }

  Widget _correctionField(TextEditingController controller, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
        style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 9,
          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none))),
    ]);
  }

  static const double _kgPerLb = 0.45359237;
  double _toDisplayWeight(double kg) => _unit == 'lb' ? kg / _kgPerLb : kg;
  double _toKgWeight(double display) => _unit == 'lb' ? display * _kgPerLb : display;

  /// Trims trailing zeros so a corrected 88.18 lb prefills cleanly.
  String _fmtNum(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }

  /// Leaving the Workout Zone — the two things that can mean, asked honestly.
  ///
  /// The previous dialog offered one action, labelled "End", and told the client
  /// "your progress won't be saved". Both were wrong. Every set is written to
  /// `workout_set_logs` as it is completed *and* as it is edited, so nothing was
  /// being discarded — and the action never touched the session row, so a
  /// workout the client had explicitly ended stayed `in_progress` for ever:
  /// still offered by the Resume banner, still holding the one active-session
  /// slot, and never counted as abandoned by `getCompletionRate()`.
  ///
  /// The two intents are genuinely different and both are supported by the
  /// session state machine that already exists (see
  /// `docs/WORKOUT_DOMAIN_CONTRACT.md` §7):
  ///
  ///  * **Leave for now** — the session stays `in_progress` with its cursor and
  ///    elapsed time, and Resume picks it up. This is what the old button
  ///    actually did.
  ///  * **End workout** — the session is `abandoned`. Set logs are kept (the
  ///    work was performed and counts toward history and volume); it stops being
  ///    resumable.
  void _showEndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave this workout?',
          style: TextStyle(color: _white, fontWeight: FontWeight.w700)),
        content: Text(
          'Every set you\'ve logged is already saved.\n\n'
          'Leave for now and you can pick up where you left off. '
          'End the workout and it stops being resumable — your logged sets are '
          'kept either way.',
          style: TextStyle(color: _muted.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going', style: TextStyle(color: _primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveForNow();
            },
            child: const Text('Leave For Now',
                style: TextStyle(color: _primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endWorkout();
            },
            child: const Text('End Workout', style: TextStyle(color: _error))),
        ]));
  }

  /// Steps away without closing the session: it stays `in_progress`, so the
  /// Resume banner offers it and the stored cursor puts the client back on the
  /// set they left.
  void _leaveForNow() {
    final sid = _sessionId;
    if (sid != null) {
      // Fire-and-forget: the elapsed clock is a convenience, and losing it must
      // not stop the client leaving.
      unawaited(_sessions.saveElapsed(sid, _elapsedSeconds).catchError((_) {}));
    }
    ref.read(activeWorkoutProvider.notifier).reset();
    ref.invalidate(activeSessionProvider);
    ref.invalidate(activeWorkoutRestorationProvider);
    context.go('/home');
  }

  /// Ends the session for good.
  ///
  /// Awaited, and a failure is surfaced rather than swallowed: navigating away
  /// from a session the database still believes is `in_progress` is precisely
  /// the defect this replaces, so the client is told when it did not close and
  /// is left on the screen to try again.
  Future<void> _endWorkout() async {
    final sid = _sessionId;
    if (sid != null) {
      try {
        await _sessions.abandonSession(sid);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not end the workout: $e'),
          backgroundColor: _error));
        return;
      }
    }
    _timer?.cancel();
    _dismissRest();
    _sessionId = null;
    ref.read(activeWorkoutProvider.notifier).reset();
    // The workout must not stay selected: the Zone treats an in-memory
    // selection as authoritative, so re-entering would start a fresh session
    // for a workout the client just ended.
    ref.read(selectedWorkoutProvider.notifier).state = null;
    ref.invalidate(activeSessionProvider);
    ref.invalidate(activeWorkoutRestorationProvider);
    if (mounted) context.go('/home');
  }
}

// ── Hydration states ──────────────────────────────────────────────────────────

/// Shown while the app is still working out whether there is an active session.
///
/// Never "No workout selected": until the lookup answers, the app does not know
/// that there isn't one, and telling a mid-session client there is nothing to
/// resume is the wrong answer to give while still asking the question.
class _RestoringWorkoutView extends StatelessWidget {
  const _RestoringWorkoutView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 34, height: 34,
            child: CircularProgressIndicator(color: _brand, strokeWidth: 3)),
          SizedBox(height: 20),
          Text('Restoring your workout…',
            style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Picking up right where you left off',
            style: TextStyle(color: _muted, fontSize: 13)),
        ]),
      ),
    );
  }
}

/// An active session exists but could not be rebuilt.
///
/// Nothing is discarded to get here — the session row is untouched and still
/// in progress — so the recovery action is simply to try again.
class _RestoreFailedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _RestoreFailedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, color: _error, size: 44),
            const SizedBox(height: 18),
            const Text('We couldn\'t restore your workout.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'Your session is safe — we just couldn\'t load it right now. '
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand, foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.refresh_rounded, size: 19),
                  SizedBox(width: 8),
                  Text('Try Again',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ]))),
            TextButton(
              onPressed: () => context.go('/train'),
              child: const Text('Back to Train', style: TextStyle(color: _muted))),
          ]),
        ),
      ),
    );
  }
}

/// The genuine empty state: the lookup completed and there is no active session.
class _NoActiveWorkoutView extends StatelessWidget {
  const _NoActiveWorkoutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.fitness_center, color: _primary, size: 48),
          const SizedBox(height: 16),
          const Text('No workout selected',
            style: TextStyle(color: _white, fontSize: 16)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/train'),
            child: const Text('Browse Workouts',
              style: TextStyle(color: _brand))),
        ]),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w500)),
    ]);
  }
}

// ── Workout Complete Dialog ────────────────────────────────────────────────────
class _WorkoutCompleteDialog extends StatefulWidget {
  final String title, duration;
  final int calories;
  final int idleSeconds;
  final String? sessionId;
  final VoidCallback onDone;
  const _WorkoutCompleteDialog({
    required this.title, required this.duration,
    required this.calories, this.idleSeconds = 0, this.sessionId, required this.onDone});
  @override
  State<_WorkoutCompleteDialog> createState() => _WorkoutCompleteDialogState();
}

class _WorkoutCompleteDialogState extends State<_WorkoutCompleteDialog> {
  int _rating = 0;
  int _energy = 0;
  int _difficulty = 0;
  final _notes = TextEditingController();
  bool _submitted = false;
  bool _saving = false;
  final _db = Supabase.instance.client;

  @override
  void dispose() { _notes.dispose(); super.dispose(); }

  Future<void> _saveFeedback() async {
    if (_rating == 0) return;
    setState(() => _saving = true);
    try {
      final uid = _db.auth.currentUser?.id;
      final rel = await _db
          .from('coach_client_relationships')
          .select('coach_id')
          .eq('client_id', uid!)
          .eq('status', 'active')
          .maybeSingle();
      await _db.from('workout_feedback').insert({
        'session_id': widget.sessionId,
        'user_id': uid,
        'coach_id': rel?['coach_id'],
        'rating': _rating,
        'energy_level': _energy > 0 ? _energy : null,
        'difficulty': _difficulty > 0 ? _difficulty : null,
        'notes': _notes.text.isEmpty ? null : _notes.text,
      });
      if (rel?['coach_id'] != null) {
        await _db.from('notifications').insert({
          'recipient_id': rel!['coach_id'],
          'type': 'workout_feedback',
          'title': 'Workout Feedback Received',
          'body': 'A client rated their workout $_rating/5 — tap to view.',
          'read': false,
        });
      }
    } catch (_) {}
    setState(() { _saving = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _brand.withValues(alpha: 0.15),
              border: Border.all(color: _brand.withValues(alpha: 0.4))),
            child: const Icon(Icons.emoji_events_rounded, color: _brand, size: 34)),
          const SizedBox(height: 16),
          const Text('Workout Complete!',
            style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(widget.title, style: TextStyle(color: _primary.withValues(alpha: 0.8), fontSize: 13)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _DialogStat(icon: Icons.timer_outlined, label: 'Duration', value: widget.duration, color: _primary),
            _DialogStat(icon: Icons.local_fire_department_outlined, label: 'Calories', value: '${widget.calories}kcal', color: _tertiary),
            _DialogStat(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Idle',
              value: '${(widget.idleSeconds ~/ 60).toString().padLeft(2, '0')}:${(widget.idleSeconds % 60).toString().padLeft(2, '0')}',
              color: widget.idleSeconds > 0 ? _error : _tertiary),
          ]),
          if (widget.idleSeconds > 0) ...[
            const SizedBox(height: 8),
            Text('${widget.idleSeconds ~/ 60}m ${widget.idleSeconds % 60}s of rest overrun — tighten it up next time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _error.withValues(alpha: 0.8), fontSize: 11)),
          ],
          const SizedBox(height: 24),
          if (!_submitted) ...[
            const Divider(color: Color(0xFF1A1020)),
            const SizedBox(height: 16),
            const Text('How was the workout?', style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _StarRow(label: 'Overall', value: _rating, onChanged: (v) => setState(() => _rating = v)),
            const SizedBox(height: 8),
            _StarRow(label: 'Energy', value: _energy, onChanged: (v) => setState(() => _energy = v)),
            const SizedBox(height: 8),
            _StarRow(label: 'Difficulty', value: _difficulty, onChanged: (v) => setState(() => _difficulty = v)),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              style: const TextStyle(color: _white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Any notes for your coach? (optional)',
                hintStyle: const TextStyle(color: _muted),
                filled: true, fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A1020))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A1020))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _brand))),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Skip', style: TextStyle(color: _muted)))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: _rating == 0 || _saving ? null : _saveFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand, foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                  : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)))),
            ]),
          ] else ...[
            const SizedBox(height: 8),
            const Icon(Icons.check_circle, color: _tertiary, size: 40),
            const SizedBox(height: 8),
            const Text('Feedback sent to your coach!', style: TextStyle(color: _tertiary, fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: widget.onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand, foregroundColor: _white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w800)))),
          ],
        ]),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _StarRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 80, child: Text(label, style: const TextStyle(color: _muted, fontSize: 12))),
    ...List.generate(5, (i) => GestureDetector(
      onTap: () => onChanged(i + 1),
      child: Icon(i < value ? Icons.star_rounded : Icons.star_border_rounded,
        color: i < value ? _brand : _muted, size: 28))),
  ]);
}

class _DialogStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _DialogStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 11)),
    ]);
  }
}

// ── Animated guide (book) icon — swells/glows so it reads as tappable ─────────
class _GuideIconPulse extends StatefulWidget {
  const _GuideIconPulse();
  @override
  State<_GuideIconPulse> createState() => _GuideIconPulseState();
}

class _GuideIconPulseState extends State<_GuideIconPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 1.0 + t * 0.22,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primary.withValues(alpha: 0.10 + t * 0.18),
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: t * 0.45), blurRadius: 6 + t * 6)],
            ),
            child: Icon(Icons.menu_book_rounded,
              color: Color.lerp(_primary.withValues(alpha: 0.7), _white, t), size: 14),
          ),
        );
      },
    );
  }
}

// ── Today's coach adjustment, applied as load guidance during the workout ─────
class _ActiveCoachBanner extends StatelessWidget {
  final CoachAdjustment adj;
  const _ActiveCoachBanner({required this.adj});

  String _cue() {
    final d = adj.intensityDelta;
    if (d <= -5) return 'Recovery focus — aim ~${d.abs()}% lighter today. Quality over quantity.';
    if (d >= 5) return 'You’re primed — push ~$d% heavier if your form holds.';
    return 'Train at your normal working loads today.';
  }

  @override
  Widget build(BuildContext context) {
    final d = adj.intensityDelta;
    final accent = d == 0 ? _primary : (d < 0 ? _amber : _tertiary);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withValues(alpha: 0.14), _card],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_rounded, color: accent, size: 16),
          const SizedBox(width: 8),
          Text('COACH ADJUSTMENT',
            style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const Spacer(),
          if (d != 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
            child: Text('${d > 0 ? '+' : ''}$d%',
              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        Text(_cue(), style: const TextStyle(color: _muted, fontSize: 13, height: 1.4)),
      ]),
    );
  }
}
