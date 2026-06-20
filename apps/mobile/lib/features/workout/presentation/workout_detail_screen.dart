import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _C {
  static const bg                  = Color(0xFF0E0E0F);
  static const surfaceContainer    = Color(0xFF201F20);
  static const surfaceContainerHigh= Color(0xFF2A2A2B);
  static const glassCard           = Color(0x99201F20);
  static const primary             = Color(0xFFDDB7FF);
  static const primaryContainer    = Color(0xFFB76DFF);
  static const inversePrimary      = Color(0xFF842BD2);
  static const onSurface           = Color(0xFFE5E2E3);
  static const onSurfaceVar        = Color(0xFFCDC3D0);
  static const outline             = Color(0xFF968E99);
  static const outlineVar          = Color(0xFF4B444F);
}

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          // Hero
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 280,
            pinned: true,
            leading: GestureDetector(
              onTap: () => context.canPop() ? context.pop() : context.go('/workouts'),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/workout-full-body.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: _C.surfaceContainer)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xCC0E0E0F), Color(0xFF0E0E0F)],
                        stops: [0.3, 0.75, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _C.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _C.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Text('INTERMEDIATE',
                        style: TextStyle(color: _C.primary, fontSize: 9,
                          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    ),
                  ),
                  const Positioned(
                    bottom: 20, left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STRENGTH PROGRAM',
                          style: TextStyle(color: _C.primary, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        SizedBox(height: 4),
                        Text('Full Body Strength',
                          style: TextStyle(color: Colors.white, fontSize: 26,
                            fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(children: [
                    _StatChip(icon: Icons.verified_outlined, label: '12 Circle'),
                    const SizedBox(width: 8),
                    _StatChip(icon: Icons.timer_outlined, label: '45 min'),
                    const SizedBox(width: 8),
                    _StatChip(icon: Icons.local_fire_department_outlined, label: '420 kcal'),
                  ]),
                  const SizedBox(height: 20),

                  // Start button
                  GestureDetector(
                    onTap: () => context.go('/active-workout'),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [_C.inversePrimary, _C.primaryContainer],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55842BD2), blurRadius: 20),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text('Start Workout',
                            style: TextStyle(color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text('About This Workout',
                    style: TextStyle(color: _C.onSurface, fontSize: 18,
                      fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'A comprehensive full-body strength program designed to build muscle, increase strength, and improve overall fitness. This workout targets all major muscle groups with compound movements.',
                    style: TextStyle(color: _C.onSurfaceVar, fontSize: 14, height: 1.6)),
                  const SizedBox(height: 24),

                  // Exercises
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Exercises',
                        style: TextStyle(color: _C.onSurface, fontSize: 18,
                          fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('8 EXERCISES',
                          style: TextStyle(color: _C.primary, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ..._exercises.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExerciseRow(index: e.key + 1, data: e.value),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _exercises = [
  ('Barbell Squat',       '4 sets × 8 reps',  'assets/images/exercise-squat.jpg'),
  ('Bench Press',         '4 sets × 8 reps',  'assets/images/exercise-bench-press.jpg'),
  ('Conventional Deadlift','3 sets × 6 reps', 'assets/images/exercise-deadlift.jpg'),
  ('Wide-Grip Pull Ups',  '3 sets × 10 reps', 'assets/images/exercise-pullups.jpg'),
  ('Overhead Press',      '3 sets × 10 reps', 'assets/images/exercise-bench-press.jpg'),
  ('Barbell Row',         '3 sets × 10 reps', 'assets/images/exercise-deadlift.jpg'),
  ('Romanian Deadlift',   '3 sets × 12 reps', 'assets/images/exercise-squat.jpg'),
  ('Dumbbell Curl',       '3 sets × 12 reps', 'assets/images/exercise-pullups.jpg'),
];

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _C.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.outlineVar.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: _C.onSurfaceVar, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _C.onSurfaceVar,
          fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final (String, String, String) data;
  const _ExerciseRow({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/exercise-detail'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.glassCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x0DFFFFFF)),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _C.inversePrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('$index',
              style: const TextStyle(color: _C.primary, fontSize: 12,
                fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48, height: 48,
              child: Image.asset(data.$3, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: _C.surfaceContainer)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.$1, style: const TextStyle(color: _C.onSurface,
                  fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(data.$2, style: const TextStyle(color: _C.onSurfaceVar,
                  fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _C.outline, size: 18),
        ]),
      ),
    );
  }
}
