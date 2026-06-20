import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/workout_log_model.dart';
import '../data/models/workout_model.dart';
import '../data/workout_service.dart';
import '../domain/workout_provider.dart';
import 'widgets/set_tracker_row.dart';
import 'widgets/rest_timer_widget.dart';
import '../../coach/data/score_service.dart';
import '../../scoring/data/score_engine.dart';

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

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});
  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _showRestTimer = false;
  int _restSeconds = 90;
  bool _saving = false;
  final _workoutService = WorkoutService();
  final _db = Supabase.instance.client;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
    _startSession();
  }

  Future<void> _startSession() async {
    final workout = ref.read(selectedWorkoutProvider);
    if (workout == null) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      // Reuse existing in_progress session for this workout (resume flow)
      final existing = await _db
          .from('workout_sessions')
          .select()
          .eq('user_id', uid)
          .eq('workout_title', workout.title)
          .eq('status', 'in_progress')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (existing != null) {
        _sessionId = existing['id'] as String;
        final savedElapsed = existing['elapsed_seconds'] as int?;
        if (savedElapsed != null && mounted) {
          setState(() => _elapsedSeconds = savedElapsed);
        }
        // Restore previously completed sets into active workout state
        final logs = await _workoutService.getSessionCompletedSets(_sessionId!);
        if (mounted && logs.isNotEmpty) {
          ref.read(activeWorkoutProvider.notifier).restoreFromLogs(logs);
        }
      } else {
        final row = await _db.from('workout_sessions').insert({
          'user_id': uid,
          'workout_title': workout.title,
          'status': 'in_progress',
          'started_at': DateTime.now().toIso8601String(),
        }).select().single();
        _sessionId = row['id'] as String;
        ScoreEngine().workoutStarted(workout.id); // +5
      }
    } catch (_) {}
  }

  Future<void> _saveElapsed() async {
    if (_sessionId == null) return;
    try {
      await _db.from('workout_sessions').update({
        'elapsed_seconds': _elapsedSeconds,
      }).eq('id', _sessionId!);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        await _db.from('workout_sessions').update({
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
          'duration_seconds': _elapsedSeconds,
          'calories_burned': log.caloriesBurned ?? 0,
        }).eq('id', _sessionId!);
      } catch (_) {}
    }

    await ScoreService().addWorkoutPoints();
    await ScoreEngine().workoutCompleted(workout.id);
    ref.read(activeWorkoutProvider.notifier).reset();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _WorkoutCompleteDialog(
          title: workout.title,
          duration: _elapsedTime,
          calories: log.caloriesBurned ?? 0,
          sessionId: _sessionId,
          onDone: () {
            Navigator.pop(context);
            context.go('/home');
          },
        ),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(selectedWorkoutProvider);
    final activeData = ref.watch(activeWorkoutProvider);

    if (workout == null) {
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

    final completedSets = activeData.values
        .expand((sets) => sets)
        .where((s) => s['completed'] == true)
        .length;
    final totalSets = workout.exercises
        .fold(0, (sum, e) => sum + e.sets.length);
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    final groups = _buildGroups(workout.exercises);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
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
                  Text(workout.title,
                    style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('Coach ${workout.coachName ?? ''}',
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

          // ── Exercise list ──
          Expanded(
            child: ListView(
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

                if (_showRestTimer) ...[
                  RestTimerWidget(
                    seconds: _restSeconds,
                    onComplete: () => setState(() => _showRestTimer = false)),
                  const SizedBox(height: 16),
                ],

                // ── Render groups (superset / circuit / solo) ──
                ...groups.map((group) {
                  if (group.isCircuit) {
                    return _buildCircuitGroup(group, activeData, workout);
                  }
                  if (group.isSuperset) {
                    return _buildSupersetGroup(group, activeData, workout);
                  }
                  return _buildExerciseCard(group.indices[0], group.items[0], activeData, workout);
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
      ),
    );
  }

  // ── Single exercise card ──────────────────────────────────────────────────
  Widget _buildExerciseCard(
    int index,
    WorkoutExercise we,
    Map<String, List<Map<String, dynamic>>> activeData,
    Workout workout,
  ) {
    final exerciseData = activeData[we.exercise.id] ?? [];
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
        _columnHeaders(),
        ..._buildSetRows(we, exerciseData),
        const SizedBox(height: 8),
      ]));
  }

  // ── Superset group ────────────────────────────────────────────────────────
  Widget _buildSupersetGroup(
    _ExGroup group,
    Map<String, List<Map<String, dynamic>>> activeData,
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
          final exerciseData = activeData[we.exercise.id] ?? [];
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
            ..._buildSetRows(we, exerciseData),
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
    Map<String, List<Map<String, dynamic>>> activeData,
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
            final exerciseData = activeData[we.exercise.id] ?? [];
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
              ..._buildSetRows(we, exerciseData),
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
          child: Text(we.exercise.name,
            style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999)),
          child: Text(we.exercise.muscleGroup,
            style: TextStyle(color: _primary.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600))),
      ]));
  }

  Widget _columnHeaders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        SizedBox(width: 36,
          child: Text('SET', style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 1))),
        Expanded(child: Text('WEIGHT', textAlign: TextAlign.center,
          style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 1))),
        const SizedBox(width: 8),
        Expanded(child: Text('REPS', textAlign: TextAlign.center,
          style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 1))),
        const SizedBox(width: 8),
        Expanded(child: Text('RPE', textAlign: TextAlign.center,
          style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 1))),
        const SizedBox(width: 74), // notes icon (28) + gap (6) + check (32) + gap (8)
      ]));
  }

  List<Widget> _buildSetRows(
    WorkoutExercise we,
    List<Map<String, dynamic>> exerciseData,
  ) {
    return we.sets.asMap().entries.map((setEntry) {
      final setIndex = setEntry.key;
      final set = setEntry.value;
      final setData = setIndex < exerciseData.length ? exerciseData[setIndex] : <String, dynamic>{};
      final isCompleted = setData['completed'] == true;

      return SetTrackerRow(
        setNumber: set.setNumber,
        targetReps: set.reps,
        targetWeight: set.weight,
        completed: isCompleted,
        tempo: set.tempo,
        onCompleted: (reps, weight, rpe, notes) {
          ref.read(activeWorkoutProvider.notifier)
              .toggleSetComplete(we.exercise.id, setIndex);
          // Save to Supabase when marking complete (not un-complete)
          if (_sessionId != null && !isCompleted) {
            _workoutService.saveSetLog(
              sessionId: _sessionId!,
              exerciseName: we.exercise.name,
              exerciseId: we.exercise.id,
              setNumber: set.setNumber,
              reps: reps,
              weightKg: weight,
              rpe: rpe,
              notes: notes,
              tempo: set.tempo,
            );
          }
          if (set.restSeconds != null && !isCompleted) {
            setState(() {
              _showRestTimer = true;
              _restSeconds = set.restSeconds!;
            });
          }
        });
    }).toList();
  }

  void _showEndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Workout?',
          style: TextStyle(color: _white, fontWeight: FontWeight.w700)),
        content: Text('Your progress won\'t be saved.',
          style: TextStyle(color: _muted.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going', style: TextStyle(color: _primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(activeWorkoutProvider.notifier).reset();
              context.go('/home');
            },
            child: const Text('End', style: TextStyle(color: _error))),
        ]));
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
  final String? sessionId;
  final VoidCallback onDone;
  const _WorkoutCompleteDialog({
    required this.title, required this.duration,
    required this.calories, this.sessionId, required this.onDone});
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
          ]),
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
