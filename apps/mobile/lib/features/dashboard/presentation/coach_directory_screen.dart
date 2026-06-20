import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_background.dart';
import '../../coach/presentation/coach_availability_screen.dart';
import '../../coach/presentation/coach_business_screen.dart';

const _white   = Colors.white;
const _muted   = Color(0xFFCFC2D6);

/// The coach-only "app directory" — opened from the middle 12 Circle button on
/// the coach bottom nav. Mirrors the client directory but with coach modules.
class CoachDirectoryScreen extends ConsumerWidget {
  const CoachDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = <_CoachTile>[
      _CoachTile('Clients', 'Manage your roster & intelligence', Icons.people_alt_rounded,
          const Color(0xFFA855F7), onTap: () => context.go('/coach-dashboard')),
      _CoachTile('Compliance', 'See who is on / off track', Icons.fact_check_rounded,
          const Color(0xFFFFD479), onTap: () => context.go('/compliance')),
      _CoachTile('Program Builder', 'Build & assign training programs', Icons.library_books_rounded,
          const Color(0xFFDDB7FF), onTap: () => context.go('/program-builder')),
      _CoachTile('Check-in Review', 'Review weekly client check-ins', Icons.rate_review_rounded,
          const Color(0xFF6FFBBE), onTap: () => context.go('/coach-checkin-review')),
      _CoachTile('Availability', 'Set bookable session slots', Icons.calendar_month_rounded,
          const Color(0xFFADC6FF), onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CoachAvailabilityScreen()))),
      _CoachTile('Packages', 'Set per-session, bulk & monthly offers', Icons.payments_rounded,
          const Color(0xFF6FFBBE), onTap: () => context.go('/coach-packages')),
      _CoachTile('My Plan', 'Your 12 Circle coach plan', Icons.workspace_premium_rounded,
          const Color(0xFFFFD479), onTap: () => context.go('/coach-plan')),
      _CoachTile('Business', 'Earnings, team & marketing', Icons.business_center_rounded,
          const Color(0xFFDDB7FF), onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CoachBusinessScreen()))),
      _CoachTile('Messages', 'Chat with your clients', Icons.chat_bubble_rounded,
          const Color(0xFFADC6FF), onTap: () => context.go('/messages')),
    ];

    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFF6FFBBE))),
                        const SizedBox(width: 8),
                        const Text('COACH TOOLS',
                            style: TextStyle(color: Color(0xFF6FFBBE), fontSize: 11,
                                fontWeight: FontWeight.w800, letterSpacing: 2)),
                      ]),
                      const SizedBox(height: 6),
                      const Text('Coach Directory',
                          style: TextStyle(color: _white, fontSize: 28,
                              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      const Text('Everything you need to run your coaching business.',
                          style: TextStyle(color: _muted, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _CoachCard(tile: tiles[i]),
                    childCount: tiles.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachTile {
  final String title, subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  _CoachTile(this.title, this.subtitle, this.icon, this.accent, {required this.onTap});
}

class _CoachCard extends StatelessWidget {
  final _CoachTile tile;
  const _CoachCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tile.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [tile.accent.withValues(alpha: 0.14), const Color(0xFF101829)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tile.accent.withValues(alpha: 0.28)),
          boxShadow: [BoxShadow(color: tile.accent.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: tile.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: tile.accent.withValues(alpha: 0.30), blurRadius: 12)]),
            child: Icon(tile.icon, color: tile.accent, size: 22)),
          const Spacer(),
          Text(tile.title,
              style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(tile.subtitle,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
