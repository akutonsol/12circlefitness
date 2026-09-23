import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/workout_model.dart';
import '../domain/workout_provider.dart';

/// FIT-016 · Workout detail — `/workout-detail`, "review before committing".
///
/// ── WHY THIS WAS REWRITTEN ─────────────────────────────────────────────────
/// The previous implementation contained **zero** data access — no `ref.`, no
/// `Supabase`, no `await`, no `Future`. It rendered one hardcoded workout with a
/// fixed hero image, so every workout in the app opened the same screen.
///
/// It was reached as the FAILURE BRANCH of a title-string match in
/// `workout_list_screen.dart`: the list recovered the domain object by comparing
/// display titles, and when that missed it navigated here with no identity at
/// all. The UI list's `'Glute & Hamstring\nFocus'` can never equal the domain's
/// `'Glute and Hamstring Focus'`, so that card always landed here — showing the
/// user a workout they had not selected.
///
/// Identity now comes from `selectedWorkoutProvider`, the same
/// `StateProvider<Workout?>` that `active_workout_screen.dart:102` already
/// reads. No new state-management pattern is introduced and no backend contract
/// is invented: every value below is a field that already exists on `Workout`,
/// `WorkoutExercise`, `WorkoutSet` and `Exercise`.
///
/// Layout is FIT-016's: back/more bar, context line, title, a three-column
/// metric strip between hairlines, the coach note, then the numbered session
/// rows and the primary CTA.
class _C {
  // Design tokens, FIT-016. Held locally for the same reason every other
  // screen in this feature does; docs/DESIGN_INTAKE_REPORT.md §10 records that
  // collapsing the per-screen palettes into context.helix is its own migration.
  static const bg      = Color(0xFF0A0A0B); // --bg
  static const ink     = Color(0xFFF4F3F6); // --ink
  static const grey    = Color(0xFF9B96A3); // --grey
  static const dim     = Color(0xFF8B8595); // --dim
  static const line    = Color(0x14FFFFFF); // --line, white 8%
  static const violet  = Color(0xFF7C3AED); // --violet
  static const white   = Color(0xFFFFFFFF); // --white, metric readouts only
}

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(selectedWorkoutProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _bar(context),
          Expanded(
            child: workout == null
                ? const _NoWorkoutSelected()
                : _Detail(workout: workout),
          ),
        ]),
      ),
    );
  }

  /// `bar` — 44x44 targets, per the design's `tap` floor.
  Widget _bar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
        child: Row(children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkResponse(
              onTap: () => context.canPop() ? context.pop() : context.go('/train'),
              radius: 24,
              child: const SizedBox(
                width: 44, height: 44,
                child: Icon(Icons.arrow_back, color: _C.grey, size: 19)),
            ),
          ),
          const Spacer(),
          // FIT-016 declares a "More" control. What it opens is not drawn on
          // the board, and GAP-04 says unlisted destinations must be asked
          // rather than assumed — so it is rendered and deliberately inert
          // rather than wired to an invented menu. Recorded as OD-10.
          Semantics(
            button: true,
            label: 'More',
            enabled: false,
            child: const SizedBox(
              width: 44, height: 44,
              child: Icon(Icons.more_horiz, color: _C.dim, size: 19)),
          ),
        ]),
      );
}

/// Distinct from a workout that failed to load: nothing was selected. Reached
/// when the list could not resolve a domain workout for the card that was
/// tapped, which is true of several browse cards that have no workout behind
/// them at all. Showing a placeholder workout here is what this screen used to
/// do, and it is the defect.
class _NoWorkoutSelected extends StatelessWidget {
  const _NoWorkoutSelected();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fitness_center, color: _C.dim, size: 48),
            const SizedBox(height: 12),
            const Text('No workout selected',
                style: TextStyle(color: _C.ink, fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            const Text('Choose a workout to see the session before you start it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.grey, fontSize: 14, height: 1.55)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go('/train'),
              child: const Text('Browse workouts', style: TextStyle(color: _C.violet)),
            ),
          ]),
        ),
      );
}

class _Detail extends StatelessWidget {
  final Workout workout;
  const _Detail({required this.workout});

  int get _setCount =>
      workout.exercises.fold<int>(0, (n, e) => n + e.sets.length);

  /// "Today · assigned by Nadia" in the design. Both halves are real fields —
  /// `scheduledDate` and `coachName` — and each is omitted when absent rather
  /// than filled with a placeholder.
  String? get _context {
    final parts = <String>[];
    final when = workout.scheduledDate;
    if (when != null) {
      final now = DateTime.now();
      final sameDay = when.year == now.year && when.month == now.month && when.day == now.day;
      parts.add(sameDay ? 'Today' : '${when.day}/${when.month}');
    }
    final coach = workout.coachName;
    if (coach != null && coach.isNotEmpty) parts.add('assigned by $coach');
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _context;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24), // `body` gutter
      children: [
        if (ctx != null) ...[
          Text(ctx.toUpperCase(), style: _mic),
          const SizedBox(height: 10),
        ],
        Text(workout.title,
            style: const TextStyle(color: _C.ink, fontSize: 24,
                fontWeight: FontWeight.w500, letterSpacing: -0.6, height: 1.1)),
        const SizedBox(height: 22),
        _MetricStrip(
          exercises: workout.exercises.length,
          minutes: workout.estimatedDuration,
          sets: _setCount,
        ),
        if (workout.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(workout.description,
              style: const TextStyle(color: _C.grey, fontSize: 14.5, height: 1.55)),
        ],
        const SizedBox(height: 26),
        Text('THE SESSION', style: _mic),
        const SizedBox(height: 8),
        if (workout.exercises.isEmpty)
          // A workout that carries no exercises is a real, if unusual, state.
          // It is NOT presented as a session that is ready to begin.
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('This workout has no exercises yet.',
                style: TextStyle(color: _C.grey, fontSize: 14)),
          )
        else
          ...workout.exercises.asMap().entries.map(
              (e) => _ExerciseRow(index: e.key + 1, exercise: e.value)),
        const SizedBox(height: 24),
        if (workout.exercises.isNotEmpty)
          // No `label:` here: the Text child supplies it. Wrapping a labelled
          // Semantics around a widget that already contains the same string
          // produces "Begin session\nBegin session" — the screen reader says it
          // twice. Verified on-device with the auth buttons.
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => context.go('/active-workout'),
              child: Container(
                height: 52, // `fc-btn`
                decoration: BoxDecoration(
                  color: _C.violet,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('Begin session',
                    style: TextStyle(color: _C.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
      ],
    );
  }

  static const _mic = TextStyle(
      color: _C.dim, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.54);
}

/// The three-column strip, between two hairlines, exactly as the board draws it.
class _MetricStrip extends StatelessWidget {
  final int exercises, minutes, sets;
  const _MetricStrip({required this.exercises, required this.minutes, required this.sets});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: _C.line),
            bottom: BorderSide(color: _C.line),
          ),
        ),
        child: Row(children: [
          Expanded(child: _cell('$exercises', 'EXERCISES')),
          Expanded(child: _cell('$minutes', 'ESTIMATED', unit: 'min')),
          Expanded(child: _cell('$sets', 'SETS')),
        ]),
      );

  Widget _cell(String value, String label, {String? unit}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `met` — white, tabular figures so the three columns align.
          Text.rich(
            TextSpan(children: [
              TextSpan(text: value),
              if (unit != null)
                TextSpan(text: unit,
                    style: const TextStyle(fontSize: 12, color: _C.grey, fontWeight: FontWeight.w400)),
            ]),
            style: const TextStyle(
                color: _C.white, fontSize: 20, fontWeight: FontWeight.w400,
                height: 1, letterSpacing: -0.4,
                fontFeatures: [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  color: _C.dim, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.54)),
        ],
      );
}

/// `row` — 22px index / title+prescription / info icon.
class _ExerciseRow extends StatelessWidget {
  final int index;
  final WorkoutExercise exercise;
  const _ExerciseRow({required this.index, required this.exercise});

  /// "4 × 6 · 65 kg · rest 120 s" — assembled only from fields that are set.
  /// A missing weight or rest is omitted rather than rendered as 0.
  ///
  /// The design also shows "3 × 10 each" for a unilateral movement. No
  /// unilateral/per-side field exists on Exercise or WorkoutSet, so "each" is
  /// NOT emitted: inventing it would mean asserting something about the
  /// prescription that the data does not say.
  String get _prescription {
    final sets = exercise.sets;
    if (sets.isEmpty) return 'No sets prescribed';
    final first = sets.first;
    final parts = <String>['${sets.length} × ${first.reps}'];
    final kg = first.weightKg;
    if (kg != null && kg > 0) {
      final s = kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toString();
      parts.add('$s kg');
    }
    final rest = first.restSeconds;
    if (rest != null && rest > 0) parts.add('rest $rest s');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final name = exercise.exercise.name;
    return Semantics(
      button: true,
      label: '$index $name $_prescription',
      // The composed label already carries position, movement and
      // prescription. Excluding the children stops it being announced twice.
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44), // `tap` floor
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _C.line)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 22,
            child: Text('$index',
                style: const TextStyle(
                    color: _C.dim, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.54)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(color: _C.ink, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(_prescription,
                  style: const TextStyle(color: _C.grey, fontSize: 12.5)),
            ]),
          ),
          const Icon(Icons.info_outline, color: _C.dim, size: 15),
        ]),
      ),
    );
  }
}
