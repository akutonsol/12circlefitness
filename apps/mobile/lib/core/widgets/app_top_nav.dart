import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/notifications/domain/notification_provider.dart';

// ── Palette (matches the new Home design) ──────────────────────────────────────
const _kMuted   = Color(0xFF8A92A6);
const _kIconBg  = Color(0xFF161B27);
const _kIconFg  = Color(0xFFC4CAD6);
const _kPink    = Color(0xFFFF4D8D);

String greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String initialsFrom(String first, String last) {
  final f = first.trim();
  final l = last.trim();
  if (f.isEmpty && l.isEmpty) return 'U';
  final a = f.isNotEmpty ? f[0] : '';
  final b = l.isNotEmpty ? l[0] : '';
  final s = '$a$b';
  return (s.isEmpty ? f.substring(0, 1) : s).toUpperCase();
}

/// The shared top nav content (avatar + greeting/name on the left, chat + bell
/// on the right). Used both by the app shell (wrapped in [AppTopNav]) and the
/// Home screen header, so the design stays consistent platform-wide.
class AppTopNavRow extends ConsumerWidget {
  const AppTopNavRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final first = (profile?['first_name'] as String?) ?? '';
    final last  = (profile?['last_name'] as String?) ?? '';
    final email = (profile?['email'] as String?) ?? '';
    final name  = first.isNotEmpty ? first : (email.isNotEmpty ? email.split('@').first : 'there');
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Row(children: [
      // Avatar — gradient ring with initials.
      GestureDetector(
        onTap: () => context.go('/profile'),
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB06BFF), Color(0xFFFF4D8D)],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A1640), Color(0xFF120A1E)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(initialsFrom(first, last),
                style: const TextStyle(
                    color: Color(0xFFD9B6FF), fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greetingForNow(),
                style: const TextStyle(color: _kMuted, fontSize: 11, fontWeight: FontWeight.w500)),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _NavIconButton(
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () => context.go('/messages'),
      ),
      const SizedBox(width: 8),
      _NavIconButton(
        icon: Icons.notifications_none_rounded,
        showDot: unread > 0,
        onTap: () => context.push('/notifications'),
      ),
    ]);
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;
  const _NavIconButton({required this.icon, this.showDot = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _kIconBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Icon(icon, color: _kIconFg, size: 18),
            if (showDot)
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _kPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kIconBg, width: 1.5),
                  ),
                ),
              ),
          ]),
        ),
      );
}

/// Full top bar for the app shell: safe-area padding + subtle bottom border.
class AppTopNav extends StatelessWidget {
  const AppTopNav({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1326),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: const AppTopNavRow(),
    );
  }
}
