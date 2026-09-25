import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CORR-G1 — a member's correction of their own health data must not fail
/// silently, and a cleared field must actually clear.
///
/// This ratchets the CURRENT state of three defects found in the
/// correction-rights audit. It is a **shrinking allowlist**: it fails when a
/// new surface joins, and it fails when a listed one is fixed, so the list
/// cannot outlive the defect. Remediation is not this phase's job.
///
/// ── WHY THE APP'S OWN CODE IS THE BASELINE ─────────────────────────────────
/// `daily_checkin_screen` + `WeeklyCheckinService.submitWeeklyCheckin` do this
/// correctly: the service returns `bool`, the screen branches on it and shows
/// *"Failed to save. Please try again."*, and `'notes': notes ?? ''` **clears**
/// rather than omitting. So the failures below are deviations from a pattern
/// this repository already established, not an absent convention.
void main() {
  String read(String p) => File(p).readAsStringSync();

  /// Source with line comments removed.
  ///
  /// Mutation testing caught this: asserting `src.contains('catch')` on the
  /// raw file was killed by the word `catch` appearing in a **comment**. That
  /// is the commented-code-as-active-code trap this programme has already been
  /// bitten by in SQL, and it would have made the guard fail on a change that
  /// altered no behaviour.
  String code(String p) => read(p)
      .split('\n')
      .map((l) {
        final i = l.indexOf('//');
        return i < 0 ? l : l.substring(0, i);
      })
      .join('\n');

  // ── 1. Women's health: the whole write surface cannot report failure ──────
  group('CORR-1 · CycleService', () {
    late String src;
    setUpAll(() => src = code('lib/features/womens_health/data/cycle_service.dart'));

    test('the guard is reading the right file', () {
      // An absent result must not read as "no defect" — the H-D1 lesson.
      expect(src, contains('class CycleService'));
      expect(src, contains("from('cycle_logs')"));
      expect(src, contains("from('cycle_symptoms')"));
    });

    test('KNOWN DEFECT: no write reports failure to the caller', () {
      // Every public write is Future<void> and the file contains no catch, so
      // a caller cannot distinguish success from failure. These are period and
      // symptom records — the most sensitive data the app holds.
      final writes = RegExp(r'Future<([^>]*)>\s+(saveSettings|logPeriod|endCurrentPeriod|logSymptoms)\(')
          .allMatches(src);
      expect(writes.length, 4,
          reason: 'the four write methods have moved or been renamed; repoint '
              'this guard in the same change rather than letting it check '
              'nothing');
      for (final m in writes) {
        expect(m.group(1), 'void',
            reason: '${m.group(2)} now returns ${m.group(1)} — if it reports '
                'failure, this entry must be REMOVED from CORR-G1 and its '
                'call sites checked for handling');
      }
      // Comment-stripped, and matched as a catch CLAUSE rather than the bare
      // word, so a comment mentioning "catch" cannot trip it.
      expect(RegExp(r'\}\s*(?:on\s+\w+\s+)?catch\s*\(').hasMatch(src), isFalse,
          reason: 'CycleService now catches. If failures are reported, delete '
              'this test — it is protecting a fixed defect.');
    });

    test('KNOWN DEFECT: a signed-out session returns as though it succeeded', () {
      // `if (uid == null) return;` in a Future<void> is indistinguishable from
      // success. The call sites then pop the sheet and bump the refresh
      // counter, so the member sees a saved state and nothing was written.
      final n = RegExp(r'if\s*\(\s*uid\s*==\s*null\s*\)\s*return\s*;').allMatches(src).length;
      expect(n, greaterThanOrEqualTo(4),
          reason: 'the silent-return arms have changed; re-audit whether the '
              'caller can now tell that nothing was persisted');
    });
  });

  // ── 2. Unit preference: a fully silent catch ─────────────────────────────
  group('CORR-2 · settings unit preference', () {
    test('KNOWN DEFECT: _persistUnit swallows its failure entirely', () {
      final src = read('lib/features/settings/presentation/settings_screen.dart');
      final i = src.indexOf('Future<void> _persistUnit(');
      expect(i, greaterThan(0), reason: '_persistUnit has moved');
      final body = src.substring(i, src.indexOf('\n  }', i));
      expect(RegExp(r'catch\s*\(_\)\s*\{\s*\}').hasMatch(body), isTrue,
          reason: '_persistUnit no longer swallows. Remove this entry from '
              'CORR-G1 — it is now protecting a fixed defect.');
    });
  });

  // ── 3. The pattern that makes a field un-clearable ───────────────────────
  group('CORR-3 · guarded writes cannot clear a value', () {
    test('KNOWN DEFECT: personal info omits empty optional fields', () {
      final src = read('lib/features/profile/presentation/personal_info_screen.dart');
      final i = src.indexOf('final payload = <String, dynamic>{');
      expect(i, greaterThan(0), reason: 'the payload builder has moved');
      final body = src.substring(i, src.indexOf('.update(payload)', i));

      // Each of these is written ONLY when non-empty, so deleting the value in
      // the UI saves nothing and the previous value survives. Erasure is part
      // of correction.
      for (final f in ['phone', 'height_cm', 'weight_kg', 'weight_goal_kg']) {
        expect(body, contains("payload['$f']"),
            reason: '$f left the payload; re-audit clearing behaviour');
      }
      expect(RegExp(r"if\s*\(_phoneCtrl\.text\.trim\(\)\.isNotEmpty\)").hasMatch(body), isTrue,
          reason: 'the phone guard changed. If the field is now written '
              'unconditionally it CAN be cleared — remove this entry.');
    });

    test('the correct pattern still exists, so the deviation is provable', () {
      // Without this, "everything omits empty values" would look like a house
      // style rather than a defect.
      final src = read('lib/features/checkins/data/weekly_checkin_service.dart');
      expect(src, contains("'notes': notes ?? ''"),
          reason: 'the one surface that CLEARS correctly has changed; CORR-G1 '
              'loses its baseline for calling the others defective');
    });
  });
}
