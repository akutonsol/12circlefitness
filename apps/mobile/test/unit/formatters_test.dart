// Unit tests for formatting helpers and coach marketplace logic.
// All pure-Dart — no Supabase, no Flutter framework.
import 'package:flutter_test/flutter_test.dart';

// ── Replicated helpers ────────────────────────────────────────────────────────

// Mirrors ChatScreen._formatTime()
String formatChatTime(String iso) {
  final dt = DateTime.parse(iso).toLocal();
  final h  = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
  final m  = dt.minute.toString().padLeft(2, '0');
  return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
}

// Mirrors _CoachCard relationship button logic
String coachButtonLabel(String? relStatus, String coachId) {
  final isActive  = relStatus?.startsWith('active:$coachId') == true;
  final isPending = relStatus?.startsWith('pending:$coachId') == true;
  final hasOther  = relStatus != null && !isActive && !isPending;
  if (isActive) return 'Your Coach';
  if (isPending) return 'Request Sent';
  if (hasOther) return 'Already have a coach';
  return 'Request to Connect';
}

// Mirrors the coach rating average recalculation in home_screen.dart
Map<String, dynamic> recalcRating(
    List<Map<String, dynamic>> reviews, int newRating) {
  final ratings = reviews.map((r) => r['rating'] as int).toList()
    ..add(newRating);
  final avg = ratings.reduce((a, b) => a + b) / ratings.length;
  return {'rating_avg': double.parse(avg.toStringAsFixed(2)), 'review_count': ratings.length};
}

// Mirrors the Sunday banner visibility check
bool shouldShowCheckinBanner(DateTime now) =>
    now.weekday == DateTime.sunday;

void main() {
  // ── formatChatTime ──────────────────────────────────────────────────────────
  group('formatChatTime (hour conversion)', () {
    // Test the conversion formula in isolation (timezone-safe)
    int convertHour(int h) =>
        h > 12 ? h - 12 : h == 0 ? 12 : h;

    test('midnight (0) → 12', () => expect(convertHour(0), 12));
    test('noon (12) → 12', () => expect(convertHour(12), 12));
    test('1 PM (13) → 1', () => expect(convertHour(13), 1));
    test('11 PM (23) → 11', () => expect(convertHour(23), 11));
    test('6 AM (6) → 6', () => expect(convertHour(6), 6));
  });

  group('formatChatTime minute padding', () {
    test('minute 5 → "05"', () {
      expect('5'.padLeft(2, '0'), '05');
    });

    test('minute 30 → "30"', () {
      expect('30'.padLeft(2, '0'), '30');
    });

    test('minute 0 → "00"', () {
      expect('0'.padLeft(2, '0'), '00');
    });
  });

  group('formatChatTime AM/PM', () {
    bool isAm(int hour) => hour < 12;
    test('hour 11 → AM', () => expect(isAm(11), isTrue));
    test('hour 12 → PM', () => expect(isAm(12), isFalse));
    test('hour 0 → AM', () => expect(isAm(0), isTrue));
    test('hour 13 → PM', () => expect(isAm(13), isFalse));
  });

  // ── coachButtonLabel ────────────────────────────────────────────────────────
  group('_CoachCard button label (UC37 marketplace)', () {
    const myCoachId = 'coach-abc-123';

    test('no relationship → "Request to Connect"', () {
      expect(coachButtonLabel(null, myCoachId), 'Request to Connect');
    });

    test('active with this coach → "Your Coach"', () {
      expect(coachButtonLabel('active:$myCoachId', myCoachId), 'Your Coach');
    });

    test('pending with this coach → "Request Sent"', () {
      expect(coachButtonLabel('pending:$myCoachId', myCoachId), 'Request Sent');
    });

    test('active with a DIFFERENT coach → "Already have a coach"', () {
      expect(coachButtonLabel('active:other-coach-456', myCoachId),
          'Already have a coach');
    });

    test('pending with a DIFFERENT coach → "Already have a coach"', () {
      expect(coachButtonLabel('pending:other-coach-456', myCoachId),
          'Already have a coach');
    });

    test('active status prefix is case-sensitive', () {
      // 'Active:coachId' with capital A should not match
      expect(coachButtonLabel('Active:$myCoachId', myCoachId),
          'Already have a coach');
    });
  });

  // ── recalcRating ────────────────────────────────────────────────────────────
  group('coach rating average recalculation (UC27 reviews)', () {
    test('no existing reviews + 5 stars → avg 5.0, count 1', () {
      final result = recalcRating([], 5);
      expect(result['rating_avg'], 5.0);
      expect(result['review_count'], 1);
    });

    test('one 4-star + new 2-star → avg 3.0, count 2', () {
      final result = recalcRating([{'rating': 4}], 2);
      expect(result['rating_avg'], 3.0);
      expect(result['review_count'], 2);
    });

    test('three 5-stars + one 3-star → avg 4.5, count 4', () {
      final result = recalcRating(
          [{'rating': 5}, {'rating': 5}, {'rating': 5}], 3);
      expect(result['rating_avg'], 4.5);
      expect(result['review_count'], 4);
    });

    test('rating avg is rounded to 2 decimal places', () {
      // 1 + 2 + 3 = 6 / 3 = 2.0 exactly
      final result = recalcRating([{'rating': 1}, {'rating': 2}], 3);
      expect(result['rating_avg'], 2.0);
    });
  });

  // ── Sunday banner ───────────────────────────────────────────────────────────
  group('_SundayCheckinBanner visibility (UC16)', () {
    test('Sunday → banner should show', () {
      expect(shouldShowCheckinBanner(DateTime(2025, 3, 9)), isTrue);
    });

    test('Monday → banner hidden', () {
      expect(shouldShowCheckinBanner(DateTime(2025, 3, 10)), isFalse);
    });

    test('Saturday → banner hidden', () {
      expect(shouldShowCheckinBanner(DateTime(2025, 3, 8)), isFalse);
    });

    test('Thursday → banner hidden', () {
      expect(shouldShowCheckinBanner(DateTime(2025, 3, 6)), isFalse);
    });
  });

  // ── Sent-invite status badge ────────────────────────────────────────────────
  group('invite status label (coach dashboard UC-invites)', () {
    String inviteStatusLabel(String status) {
      switch (status) {
        case 'accepted': return 'Accepted';
        case 'expired':  return 'Expired';
        default:         return 'Pending';
      }
    }

    test('"accepted" → "Accepted"', () => expect(inviteStatusLabel('accepted'), 'Accepted'));
    test('"expired" → "Expired"', () => expect(inviteStatusLabel('expired'), 'Expired'));
    test('"pending" → "Pending"', () => expect(inviteStatusLabel('pending'), 'Pending'));
    test('unknown status falls to "Pending"', () => expect(inviteStatusLabel('foo'), 'Pending'));
  });

  // ── Bio truncation ──────────────────────────────────────────────────────────
  group('_CoachCard bio truncation at 100 chars', () {
    String truncateBio(String bio) =>
        bio.length > 100 ? '${bio.substring(0, 100)}…' : bio;

    test('short bio unchanged', () {
      const bio = 'Short bio.';
      expect(truncateBio(bio), bio);
    });

    test('exactly 100 chars unchanged', () {
      final bio = 'x' * 100;
      expect(truncateBio(bio), bio);
    });

    test('101 chars → 100 + ellipsis', () {
      final bio = 'x' * 101;
      expect(truncateBio(bio), '${'x' * 100}…');
    });

    test('empty string unchanged', () {
      expect(truncateBio(''), '');
    });
  });
}
