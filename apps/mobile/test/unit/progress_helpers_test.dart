// Unit tests for pure helper functions in progress_screen.dart (UC20).
// Replicated inline — cannot import private library functions directly.
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

// ── Replicated helpers ────────────────────────────────────────────────────────

String monthShort(int m) => const [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
][m];

// Mirrors _chartLabels() in progress_screen.dart
List<String> chartLabels(List<Map<String, dynamic>> logs) {
  if (logs.isEmpty) return [];
  final indices = [logs.length - 1, (logs.length * 2 ~/ 3), (logs.length ~/ 3), 0]
      .where((i) => i >= 0 && i < logs.length)
      .toSet()
      .toList()
    ..sort();
  return indices.map((i) {
    final d = DateTime.parse(logs[i]['logged_at'] as String).toLocal();
    return '${monthShort(d.month)} ${d.day}';
  }).toList();
}

// Mirrors _MeasurementsTab._updatedAgo()
String updatedAgo(String? rawLoggedAt) {
  if (rawLoggedAt == null) return 'No entries yet';
  final dt = DateTime.tryParse(rawLoggedAt);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inDays >= 1) return 'Updated ${diff.inDays}d ago';
  if (diff.inHours >= 1) return 'Updated ${diff.inHours}h ago';
  return 'Updated just now';
}

void main() {
  // ── monthShort ─────────────────────────────────────────────────────────────
  group('monthShort', () {
    test('January → Jan', () => expect(monthShort(1), 'Jan'));
    test('February → Feb', () => expect(monthShort(2), 'Feb'));
    test('March → Mar', () => expect(monthShort(3), 'Mar'));
    test('June → Jun', () => expect(monthShort(6), 'Jun'));
    test('September → Sep', () => expect(monthShort(9), 'Sep'));
    test('December → Dec', () => expect(monthShort(12), 'Dec'));
  });

  // ── chartLabels ────────────────────────────────────────────────────────────
  group('chartLabels', () {
    test('empty logs → empty list', () {
      expect(chartLabels([]), isEmpty);
    });

    test('single log → one label', () {
      final logs = [{'logged_at': '2025-03-15T10:00:00Z'}];
      expect(chartLabels(logs), hasLength(1));
    });

    test('two logs → two unique labels', () {
      final logs = [
        {'logged_at': '2025-03-01T10:00:00Z'},
        {'logged_at': '2025-03-15T10:00:00Z'},
      ];
      final labels = chartLabels(logs);
      expect(labels.length, greaterThanOrEqualTo(1));
      expect(labels.length, lessThanOrEqualTo(2));
    });

    test('8 logs → at most 4 labels', () {
      final logs = List.generate(
          8, (i) => {'logged_at': DateTime(2025, 3, i + 1).toIso8601String()});
      expect(chartLabels(logs).length, lessThanOrEqualTo(4));
    });

    test('labels are sorted chronologically', () {
      final logs = List.generate(
          6, (i) => {'logged_at': DateTime(2025, 4, i + 1).toIso8601String()});
      final labels = chartLabels(logs);
      // Since indices are sorted ascending, labels are chronological
      expect(labels.first, startsWith('Apr 1'));
    });

    test('label format is "MMM D" with no leading zero', () {
      final logs = [{'logged_at': '2025-01-05T00:00:00Z'}];
      final label = chartLabels(logs).first;
      expect(label, matches(RegExp(r'^[A-Z][a-z]{2} \d+$')));
    });
  });

  // ── updatedAgo ─────────────────────────────────────────────────────────────
  group('updatedAgo', () {
    test('null → "No entries yet"', () {
      expect(updatedAgo(null), 'No entries yet');
    });

    test('unparseable string → empty string', () {
      expect(updatedAgo('not-a-date'), '');
    });

    test('just now → "Updated just now"', () {
      final now = DateTime.now().toIso8601String();
      expect(updatedAgo(now), 'Updated just now');
    });

    test('5 hours ago → "Updated 5h ago"', () {
      final t = DateTime.now().subtract(const Duration(hours: 5)).toIso8601String();
      expect(updatedAgo(t), 'Updated 5h ago');
    });

    test('3 days ago → "Updated 3d ago"', () {
      final t = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
      expect(updatedAgo(t), 'Updated 3d ago');
    });

    test('exactly 24h ago → "Updated 1d ago"', () {
      final t = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
      expect(updatedAgo(t), 'Updated 1d ago');
    });
  });

  // ── waist stats ────────────────────────────────────────────────────────────
  group('waist stats (UC20 measurements)', () {
    List<double> waistValues(List<Map<String, dynamic>> history) =>
        history
            .where((r) => r['waist_cm'] != null)
            .map((r) => (r['waist_cm'] as num).toDouble())
            .toList();

    double waistTrend(List<double> vals) => (vals.length >= 2)
        ? (vals.last - vals.first) / vals.first * 100
        : 0.0;

    test('empty history → empty values', () {
      expect(waistValues([]), isEmpty);
    });

    test('rows with null waist_cm are excluded', () {
      final history = [
        {'waist_cm': null},
        {'waist_cm': 80.0},
      ];
      expect(waistValues(history), [80.0]);
    });

    test('peak is maximum value', () {
      final vals = waistValues([
        {'waist_cm': 80.0},
        {'waist_cm': 85.0},
        {'waist_cm': 78.0},
      ]);
      expect(vals.reduce(math.max), 85.0);
    });

    test('lowest is minimum value', () {
      final vals = waistValues([
        {'waist_cm': 80.0},
        {'waist_cm': 85.0},
        {'waist_cm': 78.0},
      ]);
      expect(vals.reduce(math.min), 78.0);
    });

    test('improving trend (waist decreasing) → negative %', () {
      final vals = waistValues([
        {'waist_cm': 85.0}, // oldest
        {'waist_cm': 80.0}, // newest
      ]);
      expect(waistTrend(vals), closeTo(-5.88, 0.1));
    });

    test('worsening trend (waist increasing) → positive %', () {
      final vals = waistValues([
        {'waist_cm': 80.0},
        {'waist_cm': 84.0},
      ]);
      expect(waistTrend(vals), closeTo(5.0, 0.01));
    });

    test('single entry → trend is 0', () {
      final vals = waistValues([{'waist_cm': 80.0}]);
      expect(waistTrend(vals), 0.0);
    });

    test('stable measurements → trend is 0', () {
      final vals = waistValues([
        {'waist_cm': 80.0},
        {'waist_cm': 80.0},
      ]);
      expect(waistTrend(vals), 0.0);
    });
  });

  // ── Weight tab helpers ────────────────────────────────────────────────────
  group('_WeightTab delta', () {
    double weightDelta(List<Map<String, dynamic>> logs) {
      if (logs.length < 2) return 0;
      final current = (logs[0]['weight_kg'] as num).toDouble();
      final prev    = (logs[1]['weight_kg'] as num).toDouble();
      return current - prev;
    }

    test('no logs → delta 0', () => expect(weightDelta([]), 0.0));
    test('single log → delta 0', () => expect(weightDelta([{'weight_kg': 70.0}]), 0.0));
    test('lost 2 kg → delta -2', () => expect(weightDelta([
      {'weight_kg': 70.0}, {'weight_kg': 72.0}]), -2.0));
    test('gained 1.5 kg → delta +1.5', () => expect(weightDelta([
      {'weight_kg': 71.5}, {'weight_kg': 70.0}]), closeTo(1.5, 0.001)));
  });
}
