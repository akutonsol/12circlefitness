import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/domain/auth_provider.dart';
import '../../coaching_mode/domain/coaching_mode_provider.dart';
import '../../exercise_database/data/exercise_database_service.dart';
import '../../exercise_database/data/models/exercise_detail_model.dart';
import '../../exercise_database/domain/exercise_database_provider.dart';
import '../domain/workout_provider.dart';

class _C {
  static const bg                   = Color(0xFF0E0E0F);
  static const surfaceContainerHigh = Color(0xFF2A2A2B);
  static const glassCard            = Color(0x72201F20);
  static const primary              = Color(0xFFDDB7FF);
  static const primaryContainer     = Color(0xFFB76DFF);
  static const inversePrimary       = Color(0xFF842BD2);
  static const onSurface            = Color(0xFFE5E2E3);
  static const onSurfaceVar         = Color(0xFFCDC3D0);
  static const outline              = Color(0xFF968E99);
  static const tertiary             = Color(0xFF6FFBBE);
  static const amber                = Color(0xFFFFD580);
}

const _muscleCategories = [
  ('ALL',       Icons.grid_4x4_rounded),
  ('CHEST',     Icons.sports_gymnastics_rounded),
  ('BACK',      Icons.accessibility_new_rounded),
  ('LEGS',      Icons.directions_run_rounded),
  ('CORE',      Icons.radio_button_checked_rounded),
  ('SHOULDERS', Icons.expand_rounded),
  ('ARMS',      Icons.fitness_center_rounded),
];

class TrainHubScreen extends ConsumerStatefulWidget {
  const TrainHubScreen({super.key});
  @override
  ConsumerState<TrainHubScreen> createState() => _TrainHubScreenState();
}

class _TrainHubScreenState extends ConsumerState<TrainHubScreen> {
  int _selectedCategory = 0;
  final _searchCtrl = TextEditingController();
  String _search = '';
  final _exerciseService = ExerciseDatabaseService();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync       = ref.watch(currentStreakProvider);
    final weeklyAsync       = ref.watch(weeklyWorkoutCountProvider);
    final totalAsync        = ref.watch(totalWorkoutCountProvider);
    final activeSession     = ref.watch(activeSessionProvider);
    final prsAsync          = ref.watch(personalRecordsProvider);
    final completionAsync   = ref.watch(completionRateProvider);
    final profileAsync      = ref.watch(currentUserProfileProvider);
    final isCoach           = profileAsync.whenOrNull(data: (p) => p?['role'] == 'coach') ?? false;

    final allExercises = _exerciseService.getAllExercises();
    final catLabel = _muscleCategories[_selectedCategory].$1;
    final filtered = _exerciseService.filterExercises(
      exercises: allExercises,
      muscleGroup: catLabel == 'ALL' ? 'All'
          : catLabel[0] + catLabel.substring(1).toLowerCase(),
      search: _search,
    );

    return AppScaffold(
      navIndex: 2,
      body: Stack(children: [
        // Atmospheric background
        Positioned.fill(
          child: Image.asset('assets/images/background.png',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.58),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => Container(color: _C.bg))),

        // Scrollable content
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Modality Banner ──────────────────────────────────────────────
            Builder(builder: (ctx) {
              final mode = ref.watch(coachingModeProvider);
              if (mode == CoachingMode.aiGuided) {
                return GestureDetector(
                  onTap: () => context.go('/ai-coach'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))),
                    child: Row(children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4), size: 16),
                      const SizedBox(width: 10),
                      const Expanded(child: Text(
                        'AI-Guided mode — tap here for personalised AI workout recommendations',
                        style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12, height: 1.4))),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF06B6D4), size: 18),
                    ])));
              }
              if (mode == CoachingMode.coachGuided) {
                return GestureDetector(
                  onTap: () => context.push('/workouts'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.tertiary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.tertiary.withValues(alpha: 0.25))),
                    child: Row(children: [
                      Icon(Icons.assignment_outlined, color: _C.tertiary, size: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'Coach-Guided mode — tap to view your coach-assigned workouts',
                        style: TextStyle(color: _C.tertiary, fontSize: 12, height: 1.4))),
                      Icon(Icons.chevron_right_rounded, color: _C.tertiary, size: 18),
                    ])));
              }
              return const SizedBox.shrink();
            }),

            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TRAIN',
                    style: TextStyle(color: _C.onSurface, fontSize: 32,
                      fontWeight: FontWeight.w900, letterSpacing: -1)),
                  Row(children: [
                    _IconBtn(
                      icon: Icons.history_rounded,
                      onTap: () => context.push('/workout-history'),
                      tooltip: 'History'),
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.library_books_outlined,
                      onTap: () => context.push('/exercise-library'),
                      tooltip: 'Exercise Library'),
                  ]),
                ])),
            const SizedBox(height: 20),

            // ── Resume Workout Banner ────────────────────────────────────────
            activeSession.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (session) {
                if (session == null) return const SizedBox.shrink();
                final title = session['workout_title'] as String? ?? 'Workout';
                final startedAt = session['started_at'] as String?;
                final elapsed = startedAt != null
                    ? DateTime.now().difference(DateTime.parse(startedAt))
                    : Duration.zero;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: GestureDetector(
                    onTap: () => _resumeWorkout(session),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_C.inversePrimary.withValues(alpha: 0.3),
                            _C.primaryContainer.withValues(alpha: 0.15)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.primary.withValues(alpha: 0.4))),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _C.inversePrimary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.play_arrow_rounded,
                            color: _C.primary, size: 26)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('RESUME WORKOUT',
                            style: TextStyle(color: _C.primary, fontSize: 10,
                              fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                          const SizedBox(height: 2),
                          Text(title,
                            style: const TextStyle(color: _C.onSurface, fontSize: 16,
                              fontWeight: FontWeight.w700)),
                          Text(_formatElapsed(elapsed),
                            style: TextStyle(
                              color: _C.onSurfaceVar.withValues(alpha: 0.6), fontSize: 12)),
                        ])),
                        const Icon(Icons.chevron_right, color: _C.primary, size: 22),
                      ]))));
              }),

            // ── Stats Row ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _StatCard(
                  label: 'STREAK',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: _C.amber,
                  value: streakAsync.when(
                    data: (v) => '$v', loading: () => '—', error: (_, __) => '0')),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'THIS WEEK',
                  icon: Icons.calendar_today_outlined,
                  iconColor: _C.tertiary,
                  value: weeklyAsync.when(
                    data: (v) => '$v', loading: () => '—', error: (_, __) => '0')),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'TOTAL',
                  icon: Icons.fitness_center_rounded,
                  iconColor: _C.primary,
                  value: totalAsync.when(
                    data: (v) => '$v', loading: () => '—', error: (_, __) => '0')),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'DONE RATE',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: _C.primaryContainer,
                  value: completionAsync.when(
                    data: (v) => '${(v * 100).toStringAsFixed(0)}%',
                    loading: () => '—', error: (_, __) => '—')),
              ])),
            const SizedBox(height: 24),

            // ── Nav Tiles ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: _NavTile(
                  icon: Icons.assignment_rounded,
                  label: 'My Program',
                  sub: 'Coach assigned',
                  color: _C.primary,
                  onTap: () => context.push('/workouts'))),
                const SizedBox(width: 12),
                Expanded(child: _NavTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Exercise Library',
                  sub: 'Browse all exercises',
                  color: _C.tertiary,
                  onTap: () => context.push('/exercise-library'))),
              ])),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: _NavTile(
                  icon: Icons.history_rounded,
                  label: 'Workout History',
                  sub: 'Past sessions & PRs',
                  color: _C.amber,
                  onTap: () => context.push('/workout-history'))),
                const SizedBox(width: 12),
                Expanded(child: _NavTile(
                  icon: Icons.storage_rounded,
                  label: 'Exercise Database',
                  sub: 'Global library',
                  color: _C.primaryContainer,
                  onTap: () => context.push('/exercise-database'))),
              ])),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: _NavTile(
                  icon: Icons.show_chart_rounded,
                  label: 'Strength Progress',
                  sub: 'Track your PRs over time',
                  color: _C.tertiary,
                  onTap: () => context.push('/strength-progression'))),
                const SizedBox(width: 12),
                if (isCoach)
                  Expanded(child: _NavTile(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Create Exercise',
                    sub: 'Add to your library',
                    color: _C.primary,
                    onTap: () => context.push('/create-exercise')))
                else
                  Expanded(child: _NavTile(
                    icon: Icons.groups_rounded,
                    label: 'Coach Clients',
                    sub: 'View client stats',
                    color: _C.primary,
                    onTap: () => context.push('/coach-client-workouts'))),
              ])),
            const SizedBox(height: 28),

            // ── Personal Records ─────────────────────────────────────────────
            prsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (prs) {
                if (prs.isEmpty) return const SizedBox.shrink();
                final top = prs.take(3).toList();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PERSONAL RECORDS',
                          style: TextStyle(color: _C.onSurface, fontSize: 16,
                            fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        GestureDetector(
                          onTap: () => context.push('/workout-history'),
                          child: const Text('SEE ALL',
                            style: TextStyle(color: _C.primary, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 1.5))),
                      ])),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: top.map((pr) => _PRRow(pr: pr)).toList())),
                  const SizedBox(height: 24),
                ]);
              }),

            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _C.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                child: Row(children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: _C.outline.withValues(alpha: 0.5), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: _C.onSurface, fontSize: 14),
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search exercises...',
                        hintStyle: TextStyle(color: _C.outline, fontSize: 14),
                        border: InputBorder.none, isDense: true,
                        contentPadding: EdgeInsets.zero))),
                ]))),
            const SizedBox(height: 20),

            // ── Category tabs ────────────────────────────────────────────────
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _muscleCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final active = i == _selectedCategory;
                  final cat = _muscleCategories[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: active
                            ? _C.primary.withValues(alpha: 0.2)
                            : _C.glassCard,
                        border: Border.all(
                          color: active
                              ? _C.primary.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.08)),
                        boxShadow: active ? [
                          BoxShadow(color: _C.primary.withValues(alpha: 0.25),
                            blurRadius: 12)
                        ] : null),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(cat.$2,
                          color: active ? _C.primary : _C.onSurfaceVar, size: 22),
                        const SizedBox(height: 4),
                        Text(cat.$1.length > 6 ? cat.$1.substring(0, 5) : cat.$1,
                          style: TextStyle(
                            color: active ? _C.primary : _C.onSurfaceVar,
                            fontSize: 8,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: 1)),
                      ])));
                })),
            const SizedBox(height: 24),

            // ── Exercise header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(catLabel == 'ALL' ? 'ALL EXERCISES' : catLabel,
                    style: const TextStyle(color: _C.onSurface, fontSize: 20,
                      fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  GestureDetector(
                    onTap: () => context.push('/exercise-library'),
                    child: const Text('BROWSE ALL',
                      style: TextStyle(color: _C.primary, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5))),
                ])),
            const SizedBox(height: 16),

            // ── Exercise hero cards ──────────────────────────────────────────
            ...filtered.take(5).map((ex) => _ExerciseHeroCard(
              exercise: ex,
              onTap: () {
                ref.read(selectedExerciseDetailProvider.notifier).state = ex;
                context.push('/exercise-detail');
              })),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Center(
                  child: Text('No exercises found',
                    style: TextStyle(
                      color: _C.onSurfaceVar.withValues(alpha: 0.4), fontSize: 15)))),
          ]),
        ),
      ]),
    );
  }

  Future<void> _resumeWorkout(Map<String, dynamic> session) async {
    final title = session['workout_title'] as String? ?? '';
    // Try to find matching workout in assigned or sample workouts
    final assigned = await ref.read(assignedWorkoutsProvider.future);
    final sample   = ref.read(workoutsProvider);
    final all = [...assigned, ...sample];
    final match = all.cast<dynamic>().where((w) {
      try { return (w.title as String) == title; } catch (_) { return false; }
    }).cast<dynamic>().toList();

    if (!mounted) return;
    if (match.isNotEmpty) {
      ref.read(selectedWorkoutProvider.notifier).state = match.first;
    }
    context.go('/active-workout');
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return 'Started ${h}h ${m}m ago';
    if (m > 0) return 'Started ${m}m ago';
    return 'Just started';
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  const _StatCard({required this.label, required this.icon,
    required this.iconColor, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _C.glassCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 6),
        Text(value,
          style: const TextStyle(color: _C.onSurface, fontSize: 18,
            fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
          style: const TextStyle(color: _C.outline, fontSize: 8,
            fontWeight: FontWeight.w600, letterSpacing: 1)),
      ])));
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.sub,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 13,
            fontWeight: FontWeight.w700)),
          Text(sub, style: TextStyle(color: color.withValues(alpha: 0.6),
            fontSize: 10)),
        ])),
        Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 18),
      ])));
}

// ── PR Row ────────────────────────────────────────────────────────────────────
class _PRRow extends StatelessWidget {
  final Map<String, dynamic> pr;
  const _PRRow({required this.pr});

  @override
  Widget build(BuildContext context) {
    final name   = pr['exercise_name'] as String? ?? '';
    final weight = (pr['weight_kg'] as num?)?.toDouble() ?? 0;
    final reps   = pr['reps'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.glassCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.amber.withValues(alpha: 0.2))),
      child: Row(children: [
        const Icon(Icons.emoji_events_rounded, color: _C.amber, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(name,
          style: const TextStyle(color: _C.onSurface, fontSize: 13,
            fontWeight: FontWeight.w600))),
        Text('${weight.toStringAsFixed(1)} kg × $reps',
          style: const TextStyle(color: _C.amber, fontSize: 13,
            fontWeight: FontWeight.w700)),
      ]));
  }
}

// ── Exercise Hero Card ────────────────────────────────────────────────────────
class _ExerciseHeroCard extends StatelessWidget {
  final ExerciseDetail exercise;
  final VoidCallback onTap;
  const _ExerciseHeroCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(exercise.difficulty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 340,
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(fit: StackFit.expand, children: [
          _heroImg(exercise),

          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0xCC131314), Color(0xFF131314)],
              stops: [0.3, 0.7, 1.0],
              begin: Alignment.topCenter, end: Alignment.bottomCenter))),

          // Level chip
          Positioned(
            top: 20, left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: levelColor.withValues(alpha: 0.5))),
              child: Text(exercise.difficulty.toUpperCase(),
                style: TextStyle(color: levelColor, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)))),

          // Bottom content
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
                Text(exercise.name,
                  style: const TextStyle(color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.adjust, color: _C.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(exercise.muscleGroup.toUpperCase(),
                    style: const TextStyle(color: _C.onSurfaceVar, fontSize: 10,
                      fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(width: 8),
                  Container(width: 3, height: 3,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3))),
                  const SizedBox(width: 8),
                  Text(exercise.equipment.toUpperCase(),
                    style: const TextStyle(color: _C.onSurfaceVar, fontSize: 10,
                      fontWeight: FontWeight.w600, letterSpacing: 1)),
                ]),
              ])),
              const SizedBox(width: 16),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_C.inversePrimary, _C.primaryContainer],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: const [BoxShadow(color: Color(0x55842BD2), blurRadius: 16)]),
                child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 22)),
            ])),
        ])));
  }

  Widget _heroImg(ExerciseDetail ex) {
    if (ex.imageAssetPath != null) {
      return Image.asset(ex.imageAssetPath!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientHero(ex.muscleGroup));
    }
    if (ex.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: ex.imageUrl!, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _gradientHero(ex.muscleGroup),
        placeholder: (_, __) => _gradientHero(ex.muscleGroup));
    }
    return _gradientHero(ex.muscleGroup);
  }

  Color _levelColor(String d) {
    switch (d.toLowerCase()) {
      case 'beginner': return const Color(0xFFADC6FF);
      case 'advanced': return _C.tertiary;
      case 'elite': return _C.primary;
      default: return _C.onSurfaceVar;
    }
  }

  Widget _gradientHero(String muscle) {
    final colors = {
      'Chest': [const Color(0xFF2A1A4E), const Color(0xFF0E0E0F)],
      'Back': [const Color(0xFF0B2E1A), const Color(0xFF0E0E0F)],
      'Quads': [const Color(0xFF1A2E0B), const Color(0xFF0E0E0F)],
      'Glutes': [const Color(0xFF2E1A0B), const Color(0xFF0E0E0F)],
      'Hamstrings': [const Color(0xFF2E200B), const Color(0xFF0E0E0F)],
      'Core': [const Color(0xFF1A0B2E), const Color(0xFF0E0E0F)],
      'Shoulders': [const Color(0xFF0B1A2E), const Color(0xFF0E0E0F)],
    };
    final pair = colors[muscle] ?? [const Color(0xFF1A1A2E), const Color(0xFF0E0E0F)];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: pair,
          begin: Alignment.topLeft, end: Alignment.bottomRight)));
  }
}

// ── Icon Button ───────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _IconBtn({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: _C.glassCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Icon(icon, color: _C.onSurfaceVar, size: 20)));
}
