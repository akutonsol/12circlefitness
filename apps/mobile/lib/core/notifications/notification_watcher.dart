import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'browser_push.dart';

/// Wraps the app and surfaces every new in-app notification as a native
/// browser notification (web). Subscribes to the signed-in user's
/// notifications in realtime; the first batch only primes the "seen" set so we
/// don't replay history on load.
class NotificationWatcher extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationWatcher({super.key, required this.child});

  @override
  ConsumerState<NotificationWatcher> createState() => _NotificationWatcherState();
}

class _NotificationWatcherState extends ConsumerState<NotificationWatcher> {
  final Set<String> _seen = {};
  bool _primed = false;
  StreamSubscription? _sub;
  String? _uid;

  @override
  void initState() {
    super.initState();
    ensurePermission();
    _subscribe();
  }

  void _subscribe() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _seen.clear();
    _primed = false;
    try {
      _sub = Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('recipient_id', uid)
          .listen((rows) {
        for (final r in rows) {
          final id = r['id']?.toString();
          if (id == null || _seen.contains(id)) continue;
          _seen.add(id);
          if (_primed && r['read'] == false) {
            showBrowserNotification(
              r['title'] as String? ?? '12 Circle',
              r['body'] as String? ?? '',
            );
          }
        }
        _primed = true;
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-subscribe if the signed-in user changed (login after logout).
    _subscribe();
    return widget.child;
  }
}
