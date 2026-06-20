import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/notification_model.dart';
import '../domain/notification_provider.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF060E20);
  static const surfDim     = Color(0xFF0B1326);
  static const surfCont    = Color(0xFF171F33);
  static const primary     = Color(0xFFDDB7FF);
  static const brand       = Color(0xFFA855F7);
  static const secondary   = Color(0xFFDEB7FF);
  static const onSurface   = Color(0xFFDAE2FD);
  static const onSurfVar   = Color(0xFFCFC2D6);
  static const outline     = Color(0xFF988D9F);
  static const outlineVar  = Color(0xFF4D4354);
  static const error       = Color(0xFFFFB4AB);
  static const errCont     = Color(0xFF93000A);
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all read when screen opens (after a brief delay so the user sees the dots)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(children: [
        // Background glow
        Positioned(top: -40, right: -40,
          child: Container(width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.primary.withValues(alpha: 0.06)),)),
        Positioned(bottom: -20, left: -20,
          child: Container(width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.secondary.withValues(alpha: 0.05)),)),

        Column(children: [
          // ── App Bar ─────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: topPad + 12, left: 16, right: 16, bottom: 14),
            decoration: BoxDecoration(
              color: _C.surfDim.withValues(alpha: 0.9),
              border: Border(bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08)))),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                  child: const Icon(Icons.arrow_back, color: _C.primary, size: 20)),
              ),
              const SizedBox(width: 14),
              const Text('Notifications',
                style: TextStyle(color: _C.onSurface, fontSize: 22,
                  fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(notificationsProvider.notifier).markAllRead(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _C.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.brand.withValues(alpha: 0.25))),
                  child: const Text('Mark all read',
                    style: TextStyle(color: _C.primary, fontSize: 11,
                      fontWeight: FontWeight.w600)))),
            ]),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2)),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, color: _C.outlineVar, size: 40),
                  const SizedBox(height: 12),
                  Text('Couldn\'t load notifications',
                    style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.6))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => ref.read(notificationsProvider.notifier).refresh(),
                    child: Text('Try again',
                      style: const TextStyle(color: _C.primary, fontSize: 13))),
                ])),
              data: (list) => list.isEmpty
                  ? _EmptyState()
                  : _NotificationList(list: list),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Notification List ─────────────────────────────────────────────────────────
class _NotificationList extends ConsumerWidget {
  final List<AppNotification> list;
  const _NotificationList({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = _groupByDate(list);
    return RefreshIndicator(
      color: _C.primary,
      backgroundColor: _C.surfCont,
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _countItems(groups),
        itemBuilder: (_, i) {
          final item = _itemAt(groups, i);
          if (item is String) return _GroupHeader(label: item, count: _unreadInGroup(groups, item));
          final n = item as AppNotification;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationCard(notification: n,
              onTap: () => ref.read(notificationsProvider.notifier).markRead(n.id),
              onDismiss: () => ref.read(notificationsProvider.notifier).delete(n.id)));
        },
      ),
    );
  }

  Map<String, List<AppNotification>> _groupByDate(List<AppNotification> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<AppNotification>>{};
    for (final n in list) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final String key;
      if (d == today) {
        key = 'Today';
      } else if (d == yesterday) {
        key = 'Yesterday';
      } else {
        final diff = today.difference(d).inDays;
        key = diff < 7 ? '$diff days ago' : _formatDate(n.createdAt);
      }
      groups.putIfAbsent(key, () => []).add(n);
    }
    return groups;
  }

  String _formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';

  int _countItems(Map<String, List<AppNotification>> g) =>
      g.entries.fold(0, (sum, e) => sum + 1 + e.value.length);

  Object _itemAt(Map<String, List<AppNotification>> g, int i) {
    var cur = 0;
    for (final e in g.entries) {
      if (i == cur) return e.key;
      cur++;
      if (i < cur + e.value.length) return e.value[i - cur];
      cur += e.value.length;
    }
    return '';
  }

  int _unreadInGroup(Map<String, List<AppNotification>> g, String key) =>
      g[key]?.where((n) => !n.read).length ?? 0;

  static const _months = ['JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'];
}

// ── Group Header ──────────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _GroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10, left: 2),
    child: Row(children: [
      Text(label.toUpperCase(),
        style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.55),
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
      const Spacer(),
      if (count > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _C.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
          child: Text('$count NEW',
            style: const TextStyle(color: _C.primary, fontSize: 9,
              fontWeight: FontWeight.w700, letterSpacing: 1))),
    ]),
  );
}

// ── Notification Card ─────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final cfg = _typeConfig(n.type);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _C.errCont.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: _C.error, size: 24)),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.read
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.read
                  ? Colors.white.withValues(alpha: 0.06)
                  : cfg.color.withValues(alpha: 0.2))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon circle
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cfg.color.withValues(alpha: 0.15),
                border: Border.all(color: cfg.color.withValues(alpha: 0.2))),
              child: Center(child: Icon(cfg.icon, color: cfg.color, size: 20))),
            const SizedBox(width: 14),
            // Text body
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(n.type.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(color: cfg.color.withValues(alpha: 0.7),
                      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const Spacer(),
                  Text(_timeAgo(n.createdAt),
                    style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.4),
                      fontSize: 10)),
                ]),
                const SizedBox(height: 4),
                Text(n.title,
                  style: const TextStyle(color: _C.onSurface,
                    fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(n.body,
                  style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.85),
                    fontSize: 13, height: 1.4),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            ),
            // Unread dot
            if (!n.read) ...[
              const SizedBox(width: 10),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.primary,
                  boxShadow: [BoxShadow(
                    color: _C.primary.withValues(alpha: 0.6),
                    blurRadius: 6)]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static _TypeConfig _typeConfig(String type) {
    switch (type) {
      case 'message':
      case 'messages':
        return _TypeConfig(Icons.chat_bubble_outline_rounded, const Color(0xFF60A5FA));
      case 'weekly_checkins':
      case 'checkin':
        return _TypeConfig(Icons.check_circle_outline_rounded, const Color(0xFF34D399));
      case 'today_score':
      case 'score':
        return _TypeConfig(Icons.auto_awesome_rounded, const Color(0xFFFBBF24));
      case 'challenges':
      case 'challenge':
        return _TypeConfig(Icons.emoji_events_outlined, const Color(0xFFFB923C));
      case 'nutrition_assigned':
      case 'nutrition':
        return _TypeConfig(Icons.restaurant_outlined, const Color(0xFFA3E635));
      case 'user':
      case 'achievement':
        return _TypeConfig(Icons.local_fire_department_outlined, const Color(0xFFF87171));
      case 'coach_request':
      case 'coach':
        return _TypeConfig(Icons.person_outline_rounded, const Color(0xFFDDB7FF));
      case 'workout':
        return _TypeConfig(Icons.fitness_center_outlined, const Color(0xFF818CF8));
      default:
        return _TypeConfig(Icons.notifications_outlined, const Color(0xFFCFC2D6));
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  const _TypeConfig(this.icon, this.color);
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
        child: Icon(Icons.notifications_paused_outlined,
          color: _C.outline.withValues(alpha: 0.5), size: 36)),
      const SizedBox(height: 20),
      Text('All caught up!',
        style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.7),
          fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('No more notifications for now.',
        style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.4),
          fontSize: 13)),
    ]),
  );
}
