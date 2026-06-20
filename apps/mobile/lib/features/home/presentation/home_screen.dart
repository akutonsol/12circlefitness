import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/auth_provider.dart';
import '../../workout/domain/workout_provider.dart';
import '../../coach/domain/coach_provider.dart';
import '../../coach/domain/coach_ecosystem_provider.dart';
import '../../workout/presentation/resume_workout_banner.dart';
import '../../notifications/domain/notification_provider.dart';
import '../../coaching_mode/domain/coaching_mode_provider.dart';
import '../../messaging/domain/messaging_provider.dart' show selectedConversationProvider;
import '../../womens_health/domain/cycle_provider.dart';
import '../../womens_health/domain/cycle_phase.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFF0B1326);
  static const surfContLow  = Color(0xFF131B2E);
  static const surfContHigh = Color(0xFF222A3D);
  static const primary      = Color(0xFFDDB7FF);
  static const brand        = Color(0xFFA855F7);
  static const onSurface    = Color(0xFFDAE2FD);
  static const onSurfVar    = Color(0xFFCFC2D6);
  static const error        = Color(0xFFFFB4AB);
  static const tertiary     = Color(0xFF6FFBBE);
}

// ── User Profile ──────────────────────────────────────────────────────────────
class _UserProfile {
  final String id, firstName, lastName, email;
  const _UserProfile({required this.id, required this.firstName,
    required this.lastName, required this.email});
  String get displayName =>
      firstName.isNotEmpty ? firstName : email.split('@').first;
  factory _UserProfile.fromJson(Map<String, dynamic> j) => _UserProfile(
    id: j['id'] as String,
    firstName: j['first_name'] as String? ?? '',
    lastName: j['last_name'] as String? ?? '',
    email: j['email'] as String? ?? '',
  );
}

final userProfileProvider = FutureProvider<_UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  try {
    final data = await Supabase.instance.client
        .from('user_profiles').select().eq('id', user.id).single();
    return _UserProfile.fromJson(data);
  } catch (_) { return null; }
});

// 7-day activity bars: each value 0.0–1.0 representing relative activity that day.
// Pulls from nutrition_logs (meal count) + coaching_calls (scheduled calls).
// Returns List<double> length 7, index 0 = Monday of current week.
final weeklyActivityProvider = FutureProvider<List<double>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return List.filled(7, 0.0);
  try {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd   = weekStart.add(const Duration(days: 7));

    // Nutrition logs this week
    final nutrition = await Supabase.instance.client
        .from('nutrition_logs')
        .select('logged_at')
        .eq('user_id', uid)
        .gte('logged_at', weekStart.toIso8601String())
        .lt('logged_at', weekEnd.toIso8601String());

    // Coaching calls this week (any status)
    final calls = await Supabase.instance.client
        .from('coaching_calls')
        .select('scheduled_at')
        .eq('client_id', uid)
        .gte('scheduled_at', weekStart.toIso8601String())
        .lt('scheduled_at', weekEnd.toIso8601String());

    // Count activity per weekday (0=Mon … 6=Sun)
    final counts = List<int>.filled(7, 0);
    for (final r in (nutrition as List)) {
      final dt = DateTime.tryParse(r['logged_at'] as String? ?? '')?.toLocal();
      if (dt == null) continue;
      final dayIdx = dt.weekday - 1;
      counts[dayIdx] += 1;
    }
    for (final r in (calls as List)) {
      final dt = DateTime.tryParse(r['scheduled_at'] as String? ?? '')?.toLocal();
      if (dt == null) continue;
      final dayIdx = dt.weekday - 1;
      counts[dayIdx] += 3; // calls count more
    }

    // Normalize to 0.0–1.0 (cap at ~10 actions per day)
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return List.filled(7, 0.0);
    return counts.map((c) => (c / maxCount).clamp(0.05, 1.0)).toList();
  } catch (_) {
    return List.filled(7, 0.0);
  }
});

// ── Home Screen ───────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Home session-card hero images — rotates on each visit (first two as requested).
const _heroImages = [
  'assets/images/workout_hero.png',
  'assets/images/workout-glute.jpg',
  'assets/images/workout-full-body.jpg',
  'assets/images/workout-hiit.jpg',
  'assets/images/train-squat.jpg',
];

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelCtrl;
  late final Animation<double> _panelAnim;
  // Picked once when the home screen is (re)entered, so it changes each visit.
  final String _heroImage = _heroImages[math.Random().nextInt(_heroImages.length)];

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
    _panelAnim = CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic);
  }

  @override
  void dispose() { _panelCtrl.dispose(); super.dispose(); }

  void _openPanel() {
    HapticFeedback.mediumImpact();
    _panelCtrl.forward();
  }

  void _closePanel() => _panelCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));
    final topPad  = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final profile    = ref.watch(userProfileProvider);
    final currentUser= ref.watch(currentUserProvider);
    final metaFirst  = currentUser?.userMetadata?['first_name'] as String? ?? '';
    final fallback   = metaFirst.isNotEmpty
        ? metaFirst : currentUser?.email?.split('@').first ?? '';
    final userName   = profile.valueOrNull?.displayName ?? fallback;

    const indicatorH = 36.0;
    final headerH    = topPad + 64.0;
    final panelH     = screenH * 0.86;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(fit: StackFit.expand, children: [

        // ── Static body — fills the space below header, no scrolling ─────
        Positioned(
          top: headerH + indicatorH,
          left: 12, right: 12, bottom: 0,
          child: Builder(builder: (context) {
            final mode = ref.watch(coachingModeProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const ResumeWorkoutBanner(),
                _SundayCheckinBanner(),
                _WomensHealthBanner(),
                // AI Coach chat — visible for all modes
                _AICoachQuickCard(),
                const SizedBox(height: 8),
                // Mode-specific top card
                if (mode == CoachingMode.coachGuided) ...[
                  _BookCallQuickCard(),
                  const SizedBox(height: 8),
                ] else if (mode == CoachingMode.selfGuided) ...[
                  _MyPlanCard(),
                  const SizedBox(height: 8),
                ] else if (mode == CoachingMode.aiGuided) ...[
                  _AIQuickActionsCard(),
                  const SizedBox(height: 8),
                ],
                Expanded(child: _FitnessSessionCard(mode: mode, heroImage: _heroImage)),
                const SizedBox(height: 8),
                // Mode-specific bottom card
                if (mode == CoachingMode.coachGuided) ...[
                  _CoachTipCard(),
                  const SizedBox(height: 8),
                ] else if (mode == CoachingMode.aiGuided) ...[
                  _AIInsightCard(),
                  const SizedBox(height: 8),
                ],
              ],
            );
          }),
        ),

        // ── Fixed header + pull indicator ──────────────────────────────────
        Positioned(top: 0, left: 0, right: 0,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: headerH,
                  padding: EdgeInsets.only(top: topPad, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: _C.bg.withValues(alpha: 0.6),
                    border: Border(bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06)))),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: _UserAvatar()),
                    const SizedBox(width: 12),
                    Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Good Morning',
                        style: TextStyle(
                          color: _C.onSurfVar.withValues(alpha: 0.6),
                          fontSize: 10, fontWeight: FontWeight.w600,
                          letterSpacing: 1.5)),
                      Text(userName,
                        style: const TextStyle(color: _C.onSurface,
                          fontSize: 20, fontWeight: FontWeight.w700)),
                    ]),
                    const Spacer(),
                    _IconBtn(icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => context.go('/messages')),
                    const SizedBox(width: 8),
                    _ShakingBell(),
                  ]),
                ),
              ),
            ),
            _PullIndicator(height: indicatorH, onOpen: _openPanel),
          ])),

        // ── Scrim ──────────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _panelAnim,
          builder: (_, __) => IgnorePointer(
            ignoring: _panelAnim.value < 0.05,
            child: GestureDetector(
              onTap: _closePanel,
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.55 * _panelAnim.value))))),

        // ── Slide-down panel ───────────────────────────────────────────────
        AnimatedBuilder(
          animation: _panelAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, panelH * (_panelAnim.value - 1)),
            child: child!),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: panelH,
              child: _WellnessPulsePanel(onClose: _closePanel)))),
      ]),
    );
  }
}

// ── Pull Indicator ────────────────────────────────────────────────────────────
class _PullIndicator extends ConsumerStatefulWidget {
  final double height;
  final VoidCallback onOpen;
  const _PullIndicator({required this.height, required this.onOpen});
  @override
  ConsumerState<_PullIndicator> createState() => _PullIndicatorState();
}

class _PullIndicatorState extends ConsumerState<_PullIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bounceAnim = Tween(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _bounce, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _bounce.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(todayScoreProvider)
        .valueOrNull?['total_score'] as int? ?? 0;

    return GestureDetector(
      onTap: widget.onOpen,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 80) widget.onOpen();
      },
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [
              _C.surfContLow.withValues(alpha: 0.3),
              _C.surfContLow.withValues(alpha: 0.65),
            ]),
          border: Border(bottom: BorderSide(
            color: _C.brand.withValues(alpha: 0.18), width: 0.5))),
        child: Row(children: [
          SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              value: total / 100.0,
              strokeWidth: 2.0,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_C.primary))),
          const SizedBox(width: 10),
          Text('WELLNESS PULSE',
            style: TextStyle(
              color: _C.onSurfVar.withValues(alpha: 0.45),
              fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _C.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.brand.withValues(alpha: 0.2))),
            child: Text('$total',
              style: const TextStyle(color: _C.primary, fontSize: 10,
                fontWeight: FontWeight.w800))),
          const Spacer(),
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _bounceAnim.value), child: child!),
            child: Icon(Icons.keyboard_arrow_down_rounded,
              color: _C.primary.withValues(alpha: 0.45), size: 20)),
        ])));
  }
}

// ── Wellness Pulse Panel ──────────────────────────────────────────────────────
class _WellnessPulsePanel extends ConsumerWidget {
  final VoidCallback onClose;
  const _WellnessPulsePanel({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score     = ref.watch(todayScoreProvider).valueOrNull ?? {};
    final total     = score['total_score']      as int? ?? 0;
    final workout   = score['workout_points']   as int? ?? 0;
    final nutrition = score['nutrition_points'] as int? ?? 0;
    final habits    = score['habits_points']    as int? ?? 0;
    final checkins  = score['checkin_points']   as int? ?? 0;
    final community = score['community_points'] as int? ?? 0;
    final streak    = ref.watch(currentStreakProvider).valueOrNull ?? 0;
    final topPad    = MediaQuery.of(context).padding.top;
    final now       = DateTime.now();
    const months    = ['JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'];
    final dateStr   = '${months[now.month - 1]} ${now.day}';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF0131B2E),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 50, offset: const Offset(0, 20)),
              BoxShadow(color: _C.brand.withValues(alpha: 0.12), blurRadius: 80),
            ]),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, topPad + 20, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DAILY FOCUS',
                    style: TextStyle(color: _C.primary, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                  const Text('Wellness Pulse',
                    style: TextStyle(color: _C.onSurface, fontSize: 28,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(dateStr,
                    style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.5),
                      fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  if (streak > 0)
                    Text('STREAK: $streak DAYS',
                      style: const TextStyle(color: _C.primary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
              ]),
              const SizedBox(height: 20),

              // Score ring
              _PanelScoreSection(total: total,
                workout: workout, nutrition: nutrition, habits: habits),
              const SizedBox(height: 14),

              // Mini cards
              Row(children: [
                Expanded(child: _MiniMetricCard(
                  icon: Icons.event_available_rounded,
                  label: 'CHECK-INS',
                  value: checkins, max: 10, color: _C.primary)),
                const SizedBox(width: 12),
                Expanded(child: _MiniMetricCard(
                  icon: Icons.groups_rounded,
                  label: 'COMMUNITY',
                  value: community, max: 10, color: _C.tertiary)),
              ]),
              const SizedBox(height: 14),

              // Week bars
              const _PanelWeekProgress(),
              const SizedBox(height: 20),

              // Close handle
              GestureDetector(
                onTap: onClose,
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < -80) onClose();
                },
                child: Column(children: [
                  Center(child: Container(
                    width: 44, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 6),
                  Center(child: Text('SWIPE UP TO CLOSE',
                    style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.25),
                      fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2))),
                ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Panel Score Section ───────────────────────────────────────────────────────
class _PanelScoreSection extends StatelessWidget {
  final int total, workout, nutrition, habits;
  const _PanelScoreSection({required this.total, required this.workout,
    required this.nutrition, required this.habits});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
    decoration: BoxDecoration(
      color: _C.brand.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
    child: Column(children: [
      SizedBox(
        width: 180, height: 180,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: const Size(180, 180),
            painter: _ScoreRingPainter(progress: total / 100.0)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('12Circle Score',
              style: TextStyle(color: Color(0xFFCFC2D6),
                fontSize: 11, fontWeight: FontWeight.w500)),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFDDB7FF), Color(0xFFB76DFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ).createShader(b),
              child: Text('$total',
                style: const TextStyle(color: Colors.white,
                  fontSize: 52, fontWeight: FontWeight.w900, height: 1.0))),
            Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.trending_up_rounded, color: Color(0xFF6FFBBE), size: 14),
              SizedBox(width: 2),
              Text('+4%', style: TextStyle(color: Color(0xFF6FFBBE),
                fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ]),
          _RingDot(progress: total / 100.0),
        ])),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _SubMetric(
          icon: Icons.fitness_center_rounded, label: 'WORKOUT', value: workout)),
        Container(width: 0.5, height: 52,
          color: Colors.white.withValues(alpha: 0.07)),
        Expanded(child: _SubMetric(
          icon: Icons.local_dining_rounded, label: 'NUTRITION', value: nutrition)),
        Container(width: 0.5, height: 52,
          color: Colors.white.withValues(alpha: 0.07)),
        Expanded(child: _SubMetric(
          icon: Icons.task_alt_rounded, label: 'HABITS', value: habits)),
      ]),
    ]));
}

// ── Score Ring Painter ────────────────────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  const _ScoreRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10);

    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, progress * 2 * math.pi, false,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFDDB7FF), Color(0xFFB76DFF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

// ── Ring Dot ──────────────────────────────────────────────────────────────────
class _RingDot extends StatelessWidget {
  final double progress;
  const _RingDot({required this.progress});

  @override
  Widget build(BuildContext context) {
    const r = 80.0;
    final angle = -math.pi / 2 + progress * 2 * math.pi;
    return Transform.translate(
      offset: Offset(r * math.cos(angle), r * math.sin(angle)),
      child: Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 10),
            BoxShadow(color: _C.primary.withValues(alpha: 0.7), blurRadius: 20),
          ])));
  }
}

// ── Sub Metric ────────────────────────────────────────────────────────────────
class _SubMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _SubMetric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: _C.onSurfVar.withValues(alpha: 0.6), size: 22),
    const SizedBox(height: 6),
    Text('$value',
      style: const TextStyle(color: _C.onSurface, fontSize: 26,
        fontWeight: FontWeight.w900)),
    Text(label,
      style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.45),
        fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  ]);
}

// ── Mini Metric Card ──────────────────────────────────────────────────────────
class _MiniMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value, max;
  final Color color;
  const _MiniMetricCard({required this.icon, required this.label,
    required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.5),
            fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1)),
        Text('$value / $max',
          style: TextStyle(color: color, fontSize: 15,
            fontWeight: FontWeight.w800)),
      ])),
    ]));
}

// ── Panel Week Progress ───────────────────────────────────────────────────────
class _PanelWeekProgress extends ConsumerWidget {
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const _PanelWeekProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barsAsync = ref.watch(weeklyActivityProvider);
    final bars      = barsAsync.valueOrNull ?? List.filled(7, 0.0);
    final todayIdx  = (DateTime.now().weekday - 1).clamp(0, 6);

    // % of days this week with any activity
    final activeDays = bars.where((v) => v > 0.05).length;
    final pct = (activeDays / 7 * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("This Week's Progress",
              style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.8),
                fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(pct == 0
                ? 'Log meals or workouts to see progress'
                : pct >= 70 ? 'Excellent consistency!' : 'Keep building your streak',
              style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.35), fontSize: 11)),
          ]),
          if (barsAsync.isLoading)
            const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary))
          else
            Text('$pct%',
              style: const TextStyle(color: _C.primary, fontSize: 28,
                fontWeight: FontWeight.w900, letterSpacing: -1, height: 1)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 72,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final isToday  = i == todayIdx;
              final isPast   = i < todayIdx;
              final height   = 72 * (bars[i] > 0 ? bars[i] : (isToday ? 0.15 : 0.04));
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: isToday ? _C.brand
                      : bars[i] > 0.05
                        ? _C.brand.withValues(alpha: isPast ? 0.55 : 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isToday ? [
                      BoxShadow(color: _C.brand.withValues(alpha: 0.4), blurRadius: 14)
                    ] : null))));
            })),
        ),
        const SizedBox(height: 8),
        Row(children: List.generate(7, (i) => Expanded(
          child: Center(
            child: Text(_days[i],
              style: TextStyle(
                color: i == todayIdx
                    ? _C.primary
                    : _C.onSurfVar.withValues(alpha: 0.25),
                fontSize: 9, fontWeight: FontWeight.w700)))))),
      ]));
  }
}

// ── User Avatar ───────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: _C.primary.withValues(alpha: 0.3), width: 2),
      boxShadow: [BoxShadow(color: _C.brand.withValues(alpha: 0.25), blurRadius: 12)]),
    child: ClipOval(child: Image.asset('assets/images/dumbell.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: _C.surfContHigh,
        child: const Icon(Icons.person_rounded, color: _C.primary, size: 20)))));
}

// ── Icon Button ───────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x08FFFFFF),
        border: Border.all(color: const Color(0x0DFFFFFF))),
      child: Icon(icon, color: _C.onSurfVar, size: 20)));
}

// ── Shaking Bell ──────────────────────────────────────────────────────────────
class _ShakingBell extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ShakingBell> createState() => _ShakingBellState();
}
class _ShakingBellState extends ConsumerState<_ShakingBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shake;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 500));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(seconds: 1), _loop);
  }
  void _loop() {
    if (!mounted) return;
    _ctrl.forward(from: 0).then(
      (_) => Future.delayed(const Duration(seconds: 3), _loop));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final hasUnread = unread > 0;
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: AnimatedBuilder(
        animation: _shake,
        builder: (_, child) => Transform.rotate(
          angle: hasUnread ? _shake.value : 0, child: child),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasUnread
                ? _C.error.withValues(alpha: 0.08)
                : const Color(0x08FFFFFF),
            border: Border.all(color: hasUnread
                ? _C.error.withValues(alpha: 0.3)
                : const Color(0x0DFFFFFF))),
          child: Stack(alignment: Alignment.center, children: [
            Icon(
              hasUnread
                  ? Icons.notifications_rounded
                  : Icons.notifications_outlined,
              color: hasUnread ? _C.error : _C.onSurfVar, size: 20),
            if (hasUnread)
              Positioned(top: 7, right: 7,
                child: Container(
                  width: unread > 9 ? 13 : 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _C.error,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [BoxShadow(
                      color: _C.error.withValues(alpha: 0.6),
                      blurRadius: 4)]),
                  alignment: Alignment.center,
                  child: unread > 9
                      ? const Text('9+',
                          style: TextStyle(color: Colors.white,
                            fontSize: 6, fontWeight: FontWeight.w800))
                      : null)),
          ]))));
  }
}

// ── Women's Health Banner (female clients only) ───────────────────────────────
class _WomensHealthBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final gender = (profile?['gender'] as String?)?.toLowerCase();
    if (gender != 'female') return const SizedBox.shrink();

    final status = ref.watch(cycleStatusProvider).valueOrNull;
    final guide = status != null ? phaseGuides[status.phase]! : null;
    final color = guide?.color ?? const Color(0xFFFF6B8A);
    final subtitle = (status != null && status.hasData)
        ? '${guide!.label} · Day ${status.cycleDay}'
        : 'Track your cycle, symptoms & recovery';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.push('/womens-health'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.18), const Color(0xFF0E0B16)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(guide?.icon ?? Icons.favorite_rounded, color: color, size: 17)),
            const SizedBox(width: 10),
            Expanded(child: Row(children: [
              const Text("Women's Health",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Flexible(child: Text('· $subtitle',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
            ])),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Sunday Check-In Banner ────────────────────────────────────────────────────
class _SundayCheckinBanner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SundayCheckinBanner> createState() =>
      _SundayCheckinBannerState();
}
class _SundayCheckinBannerState extends ConsumerState<_SundayCheckinBanner> {
  bool _dismissed = false;
  bool _checkedIn = false;
  bool _checked   = false;

  @override
  void initState() { super.initState(); _checkIfCheckedIn(); }

  Future<void> _checkIfCheckedIn() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) { setState(() => _checked = true); return; }
    final now   = DateTime.now();
    final monday= now.subtract(Duration(days: (now.weekday - 1) % 7));
    final start = DateTime(monday.year, monday.month, monday.day);
    final result= await Supabase.instance.client
        .from('weekly_checkins').select('id')
        .eq('user_id', uid).gte('created_at', start.toIso8601String()).limit(1);
    if (mounted) { setState(() {
      _checkedIn = (result as List).isNotEmpty; _checked = true; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _dismissed || _checkedIn) return const SizedBox.shrink();
    if (DateTime.now().weekday != DateTime.sunday) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => context.push('/daily-checkin'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D1260), Color(0xFF1A0A3D)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.brand.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(
            color: _C.brand.withValues(alpha: 0.15), blurRadius: 20)]),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: _C.brand.withValues(alpha: 0.2)),
            child: const Icon(Icons.check_circle_outline_rounded,
              color: _C.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text("Weekly Check-In",
              style: TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text("It's Sunday! Complete your check-in to earn 10 pts",
              style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.8),
                fontSize: 12)),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: Icon(Icons.close_rounded,
              color: _C.onSurfVar.withValues(alpha: 0.5), size: 18)),
        ]),
      ),
    );
  }
}

// ── AI Coach Quick Card ───────────────────────────────────────────────────────
class _AICoachQuickCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/ai-coach'),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.brand.withValues(alpha: 0.2),
            const Color(0xFF6FFBBE).withValues(alpha: 0.1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.brand.withValues(alpha: 0.4))),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFF6FFBBE)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('AI Coach', style: TextStyle(color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w800)),
          Text('Ask about nutrition, workouts, or your progress',
            style: TextStyle(color: Color(0xFFCFC2D6), fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _C.brand.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.chat_bubble_outline_rounded,
            color: Color(0xFFDDB7FF), size: 18)),
      ]),
    ),
  );
}

// ── Book Call Quick Card ──────────────────────────────────────────────────────
class _BookCallQuickCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/book-call'),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0B16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6FFBBE).withValues(alpha: 0.3))),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF6FFBBE).withValues(alpha: 0.15),
            shape: BoxShape.circle),
          child: const Icon(Icons.video_call_rounded,
            color: Color(0xFF6FFBBE), size: 22)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Book a Coaching Call', style: TextStyle(color: Colors.white,
            fontSize: 14, fontWeight: FontWeight.w700)),
          Text('Schedule a call with your coach',
            style: TextStyle(color: Color(0xFFCFC2D6), fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right_rounded,
          color: Color(0xFF6FFBBE), size: 20),
      ]),
    ),
  );
}

// ── AI Quick Actions Card (AI Guided) ────────────────────────────────────────
class _AIQuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF0E0B16),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
          shape: BoxShape.circle),
        child: const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4), size: 18)),
      const SizedBox(width: 10),
      const Expanded(child: Text('AI-Guided Mode',
        style: TextStyle(color: Colors.white, fontSize: 13,
          fontWeight: FontWeight.w600))),
      _AIQuickBtn(
        icon: Icons.restaurant_rounded,
        label: 'Nutrition',
        color: const Color(0xFF06B6D4),
        onTap: () => context.go('/nutrition')),
      const SizedBox(width: 8),
      _AIQuickBtn(
        icon: Icons.bolt_rounded,
        label: 'Workout',
        color: _C.primary,
        onTap: () => context.go('/ai-coach')),
    ]),
  );
}

class _AIQuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AIQuickBtn({required this.icon, required this.label,
    required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11,
          fontWeight: FontWeight.w700)),
      ])));
}

// ── My Plan Card (Self Guided) ────────────────────────────────────────────────
class _MyPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go('/train'),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0B16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primary.withValues(alpha: 0.25))),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _C.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle),
          child: const Icon(Icons.grid_view_rounded,
            color: _C.primary, size: 20)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('My Plan', style: TextStyle(color: Colors.white,
            fontSize: 14, fontWeight: FontWeight.w700)),
          Text('View your personalised program and goals',
            style: TextStyle(color: Color(0xFFCFC2D6), fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded,
          color: _C.primary.withValues(alpha: 0.7), size: 20),
      ]),
    ),
  );
}

// ── AI Insight Card (AI Guided) ───────────────────────────────────────────────
class _AIInsightCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(todayScoreProvider).valueOrNull ?? {};
    final total = score['total_score'] as int? ?? 0;
    final insightText = total >= 70
        ? 'Great consistency today! Your adherence is in the top tier. Keep it up.'
        : total >= 40
          ? 'You\'re on track. Complete today\'s workout to push your score higher.'
          : 'Start with a short workout or log a meal — every action counts.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6FFBBE).withValues(alpha: 0.08),
            _C.brand.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6FFBBE).withValues(alpha: 0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6FFBBE).withValues(alpha: 0.15)),
          child: const Icon(Icons.tips_and_updates_outlined,
            color: Color(0xFF6FFBBE), size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('AI INSIGHT',
            style: TextStyle(color: Color(0xFF6FFBBE), fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(insightText,
            style: TextStyle(
              color: _C.onSurfVar.withValues(alpha: 0.9),
              fontSize: 12, height: 1.45)),
        ])),
      ]),
    );
  }
}

// ── Fitness Session Card ──────────────────────────────────────────────────────
class _FitnessSessionCard extends ConsumerWidget {
  final CoachingMode mode;
  final String heroImage;
  const _FitnessSessionCard({required this.mode, required this.heroImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAI    = mode == CoachingMode.aiGuided;
    final isCoach = mode == CoachingMode.coachGuided;

    final workouts   = ref.watch(workoutsProvider);
    final firstTitle = workouts.isNotEmpty ? workouts.first.title : 'Full Body Strength';

    final title    = isAI    ? 'AI Workout Plan'
                   : isCoach ? 'Today\'s Session'
                   :           firstTitle;
    final subtitle = isAI    ? 'Personalised by your AI coach'
                   : isCoach ? 'Assigned by your coach'
                   :           'Workout Session';
    final btnLabel = isAI    ? 'AI Train'
                   : isCoach ? 'Start Session'
                   :           'Start Circle';
    final btnColor = isAI    ? const Color(0xFF06B6D4)
                   :           const Color(0xFF8B2BE2);
    final kcalText = isAI    ? 'AI Optimised' : '550 Kcal';
    final kcalIcon = isAI    ? Icons.auto_awesome : Icons.local_fire_department_rounded;

    void onStart() {
      if (isAI) {
        context.go('/ai-coach');
        return;
      }
      if (isCoach) {
        context.go('/workouts');
        return;
      }
      final workouts = ref.read(workoutsProvider);
      if (workouts.isNotEmpty) {
        ref.read(selectedWorkoutProvider.notifier).state = workouts.first;
      }
      context.go('/active-workout');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(fit: StackFit.expand, children: [
        ColorFiltered(
          colorFilter: ColorFilter.matrix(isAI
            ? [0.0, 0.0, 0.4, 0, 0,   // AI: tint blue
               0.0, 0.2, 0.3, 0, 0,
               0.0, 0.4, 0.6, 0, 0,
               0,   0,   0,   1, 0,]
            : [1, 0, 0, 0, 0,         // non-AI: actual colour (identity)
               0, 1, 0, 0, 0,
               0, 0, 1, 0, 0,
               0, 0, 0, 1, 0,]),
          child: Image.asset(heroImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: isAI
                  ? [const Color(0xFF003040), const Color(0xFF060814)]
                  : [const Color(0xFF1A0030), const Color(0xFF0A0612)],
                begin: Alignment.topRight, end: Alignment.bottomLeft))))),
        const DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1326), Color(0xBB0B1326), Colors.transparent],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.bottomCenter, end: Alignment.topCenter))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              _SessionBadge(icon: Icons.schedule_rounded,
                text: '45 min', iconColor: _C.primary),
              const SizedBox(width: 8),
              _SessionBadge(icon: kcalIcon,
                text: kcalText,
                iconColor: isAI ? const Color(0xFF06B6D4) : const Color(0xFFA3FFCC)),
              if (isAI) ...[
                const SizedBox(width: 8),
                const _SessionBadge(icon: Icons.auto_awesome,
                  text: 'AI-Guided', iconColor: Color(0xFF06B6D4)),
              ],
            ]),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w800, height: 1.1)),
                Text(subtitle,
                  style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.7),
                    fontSize: 12)),
              ])),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(
                      color: btnColor.withValues(alpha: 0.4), blurRadius: 16)]),
                  child: Text(btnLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w700)))),
            ]),
          ])),
      ]),
    );
  }
}

class _SessionBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _SessionBadge({required this.icon, required this.text,
    required this.iconColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: iconColor, size: 11),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 10,
        fontWeight: FontWeight.w600)),
    ]));
}

// ── Coach Tip Card ────────────────────────────────────────────────────────────
class _CoachTipCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachAsync = ref.watch(assignedCoachProvider);
    final tipAsync   = ref.watch(coachTipProvider);
    final coach      = coachAsync.valueOrNull;
    final tip        = tipAsync.valueOrNull;
    final coachName  = coach == null ? null
        : '${coach['first_name'] ?? ''} ${coach['last_name'] ?? ''}'.trim();
    final avatarUrl  = coach?['avatar_url'] as String?;
    final tipText    = tip?['content'] as String?
        ?? 'Stay consistent. Small daily actions create lasting results.';

    if (coachAsync.isLoading || coach == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: _C.brand.withValues(alpha: 0.02),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 3, color: _C.brand.withValues(alpha: 0.6)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x1AFFFFFF))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _C.primary.withValues(alpha: 0.3), width: 1.5)),
                      child: ClipOval(child: avatarUrl != null
                        ? Image.network(avatarUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _CoachAvatar())
                        : _CoachAvatar())),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(coachName != null
                          ? 'Coach $coachName' : 'Your Coach',
                          style: const TextStyle(color: _C.onSurface,
                            fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _C.brand.withValues(alpha: 0.2))),
                          child: const Text("TODAY'S TIP",
                            style: TextStyle(color: _C.primary, fontSize: 8,
                              fontWeight: FontWeight.w700, letterSpacing: 0.6))),
                      ]),
                      const SizedBox(height: 4),
                      Text(tipText,
                        style: TextStyle(
                          color: _C.onSurfVar.withValues(alpha: 0.9),
                          fontSize: 12, height: 1.45)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message Coach',
                      // Open the assigned coach's chat directly (not the list,
                      // which could surface a stale conversation).
                      onTap: () {
                        ref.read(selectedConversationProvider.notifier).state =
                            {'participant': coach};
                        context.go('/chat');
                      })),
                    const SizedBox(width: 10),
                    Expanded(child: _ActionBtn(
                      icon: Icons.star_rounded,
                      label: 'Rate Coach',
                      onTap: () => _showRateCoachDialog(
                        context, coach['id'] as String))),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

void _showRateCoachDialog(BuildContext context, String coachId) {
  int selectedStars = 5;
  final textCtrl = TextEditingController();
  bool saving = false;
  showDialog(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setSt) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rate Your Coach',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('How has your coaching experience been?',
            style: TextStyle(color: Color(0xFFCFC2D6), fontSize: 13)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setSt(() => selectedStars = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < selectedStars
                    ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFA855F7), size: 36))))),
          const SizedBox(height: 16),
          TextField(
            controller: textCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)',
              hintStyle: const TextStyle(color: Color(0xFF666666)),
              filled: true,
              fillColor: const Color(0xFF0B0B0D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2A3D))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2A3D))))),
        ]),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(),
            child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF666666)))),
          TextButton(
            onPressed: saving ? null : () async {
              setSt(() => saving = true);
              try {
                final uid =
                    Supabase.instance.client.auth.currentUser?.id;
                if (uid == null) return;
                await Supabase.instance.client.from('coach_reviews').upsert({
                  'coach_id': coachId, 'client_id': uid,
                  'rating': selectedStars,
                  'review_text': textCtrl.text.trim().isEmpty
                    ? null : textCtrl.text.trim(),
                  'created_at': DateTime.now().toIso8601String(),
                }, onConflict: 'coach_id,client_id');
                final reviews = await Supabase.instance.client
                    .from('coach_reviews').select('rating')
                    .eq('coach_id', coachId);
                final ratings = (reviews as List)
                    .map((r) => (r['rating'] as int)).toList();
                final avg = ratings.isEmpty ? 0.0
                    : ratings.reduce((a, b) => a + b) / ratings.length;
                await Supabase.instance.client.from('user_profiles').update({
                  'rating_avg': avg, 'review_count': ratings.length,
                }).eq('id', coachId);
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Review submitted! Thank you.'),
                    backgroundColor: Color(0xFFA855F7)));
                }
              } catch (_) { setSt(() => saving = false); }
            },
            child: saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFFA855F7), strokeWidth: 2))
              : const Text('Submit', style: TextStyle(color: Color(0xFFA855F7),
                  fontWeight: FontWeight.w700))),
        ],
      ),
    ),
  );
}

class _CoachAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: _C.surfContHigh,
    child: const Icon(Icons.person_rounded, color: _C.primary, size: 22));
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1AFFFFFF))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _C.onSurface, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _C.onSurface, fontSize: 12,
          fontWeight: FontWeight.w700)),
      ])));
}
