import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../../features/auth/domain/auth_provider.dart';
import '../../features/notifications/domain/notification_provider.dart';
import '../theme/app_background.dart';

class _C {
  static const surface          = Color(0xFF131314);
  static const surfaceContainer = Color(0xFF201F20);
  static const primary          = Color(0xFFDDB7FF);
  static const onSurface        = Color(0xFFE5E2E3);
  static const onSurfaceVar     = Color(0xFFCDC3D0);
  static const outlineVar       = Color(0xFF4B444F);
  static const error            = Color(0xFFFFB4AB);
}

class AppScaffold extends ConsumerWidget {
  final Widget body;
  final int navIndex;
  final String? title;
  final bool showBackButton;

  const AppScaffold({
    super.key,
    required this.body,
    required this.navIndex,
    this.title,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync  = ref.watch(currentUserProfileProvider);
    final currentUser   = ref.watch(currentUserProvider);
    // Try profile first, then user metadata, then email prefix
    final firstName = (profileAsync.valueOrNull?['first_name'] as String?)?.trim().isNotEmpty == true
        ? profileAsync.valueOrNull!['first_name'] as String
        : (currentUser?.userMetadata?['first_name'] as String?)?.trim().isNotEmpty == true
            ? currentUser!.userMetadata!['first_name'] as String
            : currentUser?.email?.split('@').first ?? '';
    final avatarUrl = (profileAsync.valueOrNull?['avatar_url'] as String?)
        ?? (currentUser?.userMetadata?['avatar_url'] as String?);

    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _AppHeader(
              title: title,
              showBackButton: showBackButton,
              firstName: firstName,
              avatarUrl: avatarUrl,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final String? title;
  final bool showBackButton;
  final String firstName;
  final String? avatarUrl;
  const _AppHeader({this.title, this.showBackButton = false, required this.firstName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(left: showBackButton ? 8 : 20, right: 20, top: top),
      height: top + 64,
      decoration: BoxDecoration(
        color: _C.surface.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF353436).withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _C.primary, size: 20),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            )
          else
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: _UserAvatar(avatarUrl: avatarUrl),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: title != null
                ? Text(title!,
                    style: const TextStyle(color: _C.primary, fontSize: 18,
                      fontWeight: FontWeight.w800, letterSpacing: 2))
                : _HomeGreeting(firstName: firstName),
          ),
          const _ShakingBellIcon(),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  const _UserAvatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _C.primary, width: 2),
        boxShadow: [BoxShadow(color: _C.primary.withValues(alpha: 0.4), blurRadius: 15)],
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(avatarUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar())
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() => Container(
    color: _C.surfaceContainer,
    child: const Icon(Icons.person, color: _C.primary, size: 20));
}

class _HomeGreeting extends StatelessWidget {
  final String firstName;
  const _HomeGreeting({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'GOOD MORNING'
        : hour < 17 ? 'GOOD AFTERNOON'
        : 'GOOD EVENING';
    final displayName = firstName.isNotEmpty ? firstName
        : Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'there';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(greeting,
          style: const TextStyle(color: _C.primary, fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 2)),
        Row(children: [
          Text(displayName,
            style: const TextStyle(color: _C.onSurface, fontSize: 20,
              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(width: 4),
          Icon(Icons.bolt, color: _C.primary, size: 20),
        ]),
      ],
    );
  }
}

class _ShakingBellIcon extends ConsumerStatefulWidget {
  const _ShakingBellIcon();
  @override
  ConsumerState<_ShakingBellIcon> createState() => _ShakingBellIconState();
}

class _ShakingBellIconState extends ConsumerState<_ShakingBellIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(seconds: 1), _startShake);
  }

  void _startShake() {
    if (!mounted) return;
    _ctrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(seconds: 3), _startShake);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // Real unread count drives the badge; tap opens the notifications screen.
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    return GestureDetector(
      onTap: () => context.go('/notifications'),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (_, child) => Transform.rotate(
          angle: unread > 0 ? _shake.value : 0, child: child),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications, color: _C.primary, size: 26),
            if (unread > 0)
              Positioned(
                top: -3, right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  decoration: BoxDecoration(
                    shape: unread > 9 ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: unread > 9 ? BorderRadius.circular(8) : null,
                    color: _C.error,
                    boxShadow: [BoxShadow(color: _C.error.withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                  alignment: Alignment.center,
                  child: Text(unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(color: Color(0xFF3A0A06), fontSize: 9,
                      fontWeight: FontWeight.w800, height: 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: bottom + 12),
      decoration: BoxDecoration(
        color: _C.surfaceContainer.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: _C.outlineVar.withValues(alpha: 0.1))),
        boxShadow: const [BoxShadow(color: Color(0x26842BD2), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _NavItem(icon: Icons.grid_view_rounded,        label: 'Overview', index: 0, current: currentIndex, route: '/home'),
          _NavItem(icon: Icons.calendar_today_outlined,  label: 'Appts',    index: 1, current: currentIndex, route: '/appointments'),
          _AnimatedFab(onTap: () => context.go('/directory')),
          _NavItem(icon: Icons.show_chart_outlined,      label: 'Track',    index: 3, current: currentIndex, route: '/progress'),
          _NavItem(icon: Icons.chat_bubble_outline,      label: 'Messages', index: 4, current: currentIndex, route: '/messages'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.index,
    required this.current, required this.route});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: active ? BoxDecoration(
          color: _C.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.primary.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: _C.primary.withValues(alpha: 0.2), blurRadius: 10)],
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _C.primary : _C.onSurfaceVar.withValues(alpha: 0.6), size: 24),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                color: active ? _C.primary : _C.onSurfaceVar.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedFab({required this.onTap});
  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pingCtrl;
  late final Animation<double> _pingScale;
  late final Animation<double> _pingOpacity;

  @override
  void initState() {
    super.initState();
    _pingCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _pingScale = Tween<double>(begin: 1.0, end: 1.5)
        .animate(CurvedAnimation(parent: _pingCtrl, curve: Curves.easeOut));
    _pingOpacity = Tween<double>(begin: 0.3, end: 0.0)
        .animate(CurvedAnimation(parent: _pingCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pingCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: SizedBox(
          width: 64, height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pingCtrl,
                builder: (_, __) => Transform.scale(
                  scale: _pingScale.value,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF842BD2).withValues(alpha: _pingOpacity.value * 2),
                        width: 2.5)))),
              ),
              Image.asset('assets/images/12circle-fab.png',
                width: 64, height: 64, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF1A0D2E), Color(0xFF0D0B1A)],
                      center: Alignment.topLeft, radius: 1.2)),
                  child: const Center(
                    child: Text('12',
                      style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: -1))))),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element — kept for compatibility
class _FabArcPainter extends CustomPainter {
  const _FabArcPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 1.55 * math.pi, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0, endAngle: 2 * math.pi,
          colors: const [Color(0xFFA855F7), Color(0xFFD164E2), Colors.transparent],
          stops: const [0.0, 0.5, 0.76],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_FabArcPainter _) => false;
}
