import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// ── UC10: Resume Incomplete Workout Banner ────────────────────────────────────
// Drop this widget anywhere in the home/train hub screen to show the prompt
// when a user has an in-progress workout session.

class ResumeWorkoutBanner extends StatefulWidget {
  const ResumeWorkoutBanner({super.key});
  @override
  State<ResumeWorkoutBanner> createState() => _ResumeWorkoutBannerState();
}

class _ResumeWorkoutBannerState extends State<ResumeWorkoutBanner> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _session;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final session = await _db
          .from('workout_sessions')
          .select('*, program_workouts(name)')
          .eq('user_id', uid)
          .eq('status', 'in_progress')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (mounted && session != null) {
        setState(() => _session = session);
      }
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    final id = _session?['id'] as String?;
    if (id != null) {
      await _db.from('workout_sessions').update({'status': 'abandoned'}).eq('id', id).catchError((_) {});
    }
    setState(() { _dismissed = true; _session = null; });
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null || _dismissed) return const SizedBox.shrink();

    final startedAt = DateTime.tryParse(_session?['started_at'] as String? ?? '');
    final elapsed = startedAt != null ? DateTime.now().difference(startedAt) : Duration.zero;
    final mins = elapsed.inMinutes;
    final workoutName = (_session?['program_workouts'] as Map?)?['name'] as String? ?? 'Workout';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0F2E), Color(0xFF0F1A0F)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFA855F7).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFA855F7), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Resume Workout?',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('$workoutName • $mins min elapsed',
            style: const TextStyle(color: Color(0xFFCFC2D6), fontSize: 12)),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => context.push('/active-workout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA855F7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _dismiss,
          icon: const Icon(Icons.close_rounded, color: Color(0xFFCFC2D6), size: 18),
          padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    );
  }
}
