// Unit tests for the Sunday check-in reminder logic (UC16).
// The actual logic lives in supabase/functions/send-checkin-reminder/index.ts
// (TypeScript/Deno). We replicate the client-filtering algorithm here in Dart
// to verify correctness without a Deno runtime.
import 'package:flutter_test/flutter_test.dart';

// ── Replicated algorithm from index.ts ───────────────────────────────────────

/// Mirrors the TypeScript:
///   monday.setDate(now.getDate() - ((now.getDay() + 6) % 7))
DateTime startOfWeek(DateTime now) {
  // Dart DateTime.weekday: 1=Mon … 7=Sun
  // The TS formula uses JS getDay() where 0=Sun…6=Sat.
  // We replicate the behaviour: Monday of the current week at 00:00 UTC.
  final daysFromMonday = (now.weekday - 1) % 7; // 0 for Mon, 6 for Sun
  return DateTime.utc(now.year, now.month, now.day - daysFromMonday);
}

/// Mirrors the TypeScript filter:
///   needsReminder = relationships.filter(r => !checkedInIds.has(r.client_id))
List<Map<String, dynamic>> clientsNeedingReminder(
  List<Map<String, dynamic>> relationships,
  Set<String> checkedInIds,
) =>
    relationships
        .where((r) => !checkedInIds.contains(r['client_id'] as String))
        .toList();

/// Mirrors the notification row construction in the edge function.
Map<String, dynamic> buildNotificationRow(String clientId) => {
      'recipient_id': clientId,
      'type':         'checkin_reminder',
      'title':        'Weekly Check-In Reminder',
      'body':         "It's Sunday! Time to complete your weekly check-in and keep your streak alive.",
      'data':         {'action': 'open_checkin'},
      'read':         false,
    };

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('startOfWeek', () {
    test('Monday is already start of week', () {
      final monday = DateTime.utc(2025, 3, 10); // known Monday
      expect(startOfWeek(monday), DateTime.utc(2025, 3, 10));
    });

    test('Sunday returns previous Monday', () {
      final sunday = DateTime.utc(2025, 3, 16); // Sunday
      expect(startOfWeek(sunday), DateTime.utc(2025, 3, 10));
    });

    test('Wednesday returns same-week Monday', () {
      final wednesday = DateTime.utc(2025, 3, 12);
      expect(startOfWeek(wednesday), DateTime.utc(2025, 3, 10));
    });

    test('Saturday returns same-week Monday', () {
      final saturday = DateTime.utc(2025, 3, 15);
      expect(startOfWeek(saturday), DateTime.utc(2025, 3, 10));
    });
  });

  group('clientsNeedingReminder', () {
    final relationships = [
      {'client_id': 'client-A', 'coach_id': 'coach-1'},
      {'client_id': 'client-B', 'coach_id': 'coach-1'},
      {'client_id': 'client-C', 'coach_id': 'coach-2'},
    ];

    test('no check-ins → all clients need reminder', () {
      final result = clientsNeedingReminder(relationships, {});
      expect(result.length, 3);
    });

    test('all checked in → empty result', () {
      final result = clientsNeedingReminder(
          relationships, {'client-A', 'client-B', 'client-C'});
      expect(result, isEmpty);
    });

    test('partial check-ins → only unchecked clients', () {
      final result = clientsNeedingReminder(relationships, {'client-A'});
      expect(result.map((r) => r['client_id']).toList(),
          containsAll(['client-B', 'client-C']));
      expect(result.length, 2);
    });

    test('empty relationships → empty result', () {
      expect(clientsNeedingReminder([], {'client-A'}), isEmpty);
    });
  });

  group('buildNotificationRow', () {
    test('has correct type', () {
      final row = buildNotificationRow('client-XYZ');
      expect(row['type'], 'checkin_reminder');
    });

    test('has correct recipient_id', () {
      final row = buildNotificationRow('client-XYZ');
      expect(row['recipient_id'], 'client-XYZ');
    });

    test('read is false', () {
      final row = buildNotificationRow('client-XYZ');
      expect(row['read'], isFalse);
    });

    test('data contains open_checkin action', () {
      final row = buildNotificationRow('client-XYZ');
      expect((row['data'] as Map)['action'], 'open_checkin');
    });

    test('title and body are non-empty', () {
      final row = buildNotificationRow('client-XYZ');
      expect((row['title'] as String).isNotEmpty, isTrue);
      expect((row['body'] as String).isNotEmpty, isTrue);
    });
  });
}
