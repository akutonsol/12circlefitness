import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Emits an incrementing tick whenever `table` changes anywhere (INSERT/UPDATE/
/// DELETE). Watch this inside a FutureProvider to make it re-fetch live — no
/// manual refresh. The table must be in the Supabase realtime publication.
final tableTickerProvider = StreamProvider.family<int, String>((ref, table) {
  final db = Supabase.instance.client;
  final controller = StreamController<int>();
  var n = 0;
  controller.add(0); // initial tick so the watcher fetches immediately

  final channel = db.channel('rt-$table-${DateTime.now().microsecondsSinceEpoch}');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) {
          if (!controller.isClosed) controller.add(++n);
        },
      )
      .subscribe();

  ref.onDispose(() {
    db.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
