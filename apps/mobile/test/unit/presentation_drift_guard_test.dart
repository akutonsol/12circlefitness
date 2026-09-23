import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards over the presentation layer, in the shape the rest of this
/// suite already uses: they read committed source and assert a property of it.
///
/// These are DRIFT guards, not conformance guards. The distinction matters and
/// is stated here so a later reader does not mistake one for the other.
///
/// `docs/MOBILE_QA_SWEEP_2026-09-22.md` §4 measured the presentation layer
/// against the contract at `lib/core/helix/helix_semantics.dart:5-7`
/// ("Components consume ONLY these — never raw hex") and found it honoured
/// nowhere: 0 of 158 presentation files read `context.helix`, against 3,009
/// non-semantic colour references and 20 files declaring their own private
/// palette. Closing that gap is a design decision with an owner, not a QA
/// repair, and nothing here attempts it.
///
/// What these guards do instead is hold the line where it currently sits, so
/// the gap cannot quietly widen while that decision is outstanding. A guard
/// that fails today would have to be either weakened or allowlisted into
/// meaninglessness; a guard that pins today's count does real work.
void main() {
  final presentationFiles = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => f.path.contains('/presentation/'))
      .toList();

  group('A-G1 a declared tooltip must actually reach the widget tree', () {
    /// The defect this pins was real and shipped: `_IconBtn` in
    /// `train_hub_screen.dart` declared `final String tooltip` as a REQUIRED
    /// parameter and its build returned a bare GestureDetector, so the string
    /// reached neither a Tooltip nor the semantics tree. Two call sites passed
    /// 'History' and 'Exercise Library' believing they labelled the control.
    /// They did not, and a screen reader announced nothing.
    ///
    /// A required parameter that is never read is unambiguously a defect
    /// rather than a design choice, which is why this one was repaired and the
    /// broader labelling question was not.
    test('no widget class declares a tooltip field it never reads', () {
      final offenders = <String>[];

      for (final file in presentationFiles) {
        final source = file.readAsStringSync();
        if (!RegExp(r'final\s+String\??\s+tooltip\s*;').hasMatch(source)) {
          continue;
        }
        // Declared. It must then be CONSUMED — as a Tooltip message, or passed
        // into another widget's tooltip/semantics slot.
        //
        // `required this.tooltip` in the constructor is NOT consumption, and
        // an earlier draft of this guard counted it as such. The mutation test
        // that reverts _IconBtn to its bare-GestureDetector form caught the
        // false negative: the specific assertion below failed while this scan
        // stayed green. Constructor initialisers are therefore stripped before
        // the check.
        final body = source.replaceAll(RegExp(r'this\.tooltip'), '');
        final consumed = RegExp(
          r'message\s*:\s*tooltip|tooltip\s*:\s*tooltip|'
          r'semanticLabel\s*:\s*tooltip|Tooltip\s*\(\s*message',
        ).hasMatch(body);
        if (!consumed) offenders.add(file.path);
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These files declare a `tooltip` field and never use it. The value '
            'is accepted and discarded, so the control is unlabelled and the '
            'caller is misled:\n  ${offenders.join('\n  ')}',
      );
    });

    test('_IconBtn specifically carries its tooltip into the tree', () {
      final source = File(
        'lib/features/workout/presentation/train_hub_screen.dart',
      ).readAsStringSync();

      expect(
        source,
        contains(RegExp(r'Tooltip\(\s*message:\s*tooltip', dotAll: true)),
        reason:
            '_IconBtn must pass its required `tooltip` to a Tooltip, which '
            'also supplies the semantics label. A bare GestureDetector '
            'silently drops it.',
      );
    });
  });

  group('A-G2 no auth screen may show a user a raw error object', () {
    /// Confirmed at runtime on Android (emulator-5554, API 35): signing in with
    /// a wrong password put this on screen, in a SnackBar, for the user:
    ///
    ///   AuthApiException(message: Invalid login credentials, statusCode: 400,
    ///   code: invalid_credentials)
    ///
    /// That is `AuthException.toString()`. All four auth screens did the same
    /// thing — the entire unauthenticated surface. The repair reads the
    /// provider's own `message` field via `authErrorText` and sends the raw
    /// object to `reportError` instead.
    ///
    /// This guard is deliberately scoped to `features/auth/presentation`. The
    /// same shape exists elsewhere in the tree and is NOT repaired here; that
    /// is recorded in docs/MOBILE_QA_SWEEP_2026-09-22.md §23, not silently
    /// pinned by a guard that would have to be weakened to pass.
    final authFiles = Directory('lib/features/auth/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('no auth screen stringifies a caught error into UI text', () {
      final offenders = <String>[];

      // `Text(e.toString())`, `_showError(e.toString())`,
      // `_snack(error.toString())`, `Text('$e')` — the shapes actually found.
      final raw = RegExp(
        r"\b(?:e|err|error)\!?\.toString\(\)|"
        r"Text\(\s*'\$\{?(?:e|err|error)\}?'\s*\)",
      );

      for (final file in authFiles) {
        for (final line in file.readAsLinesSync()) {
          final code = line.split('//').first;
          if (raw.hasMatch(code)) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'An auth screen puts a caught error object into user-facing text. '
            'Use `authErrorText(e)` for the user and `reportError(...)` for the '
            'operator:\n  ${offenders.join('\n  ')}',
      );
    });

    test('authErrorText exists and reads the provider message field', () {
      final src = File('lib/core/errors/auth_error_text.dart');
      expect(src.existsSync(), isTrue,
          reason: 'lib/core/errors/auth_error_text.dart is the seam the auth '
              'screens depend on.');
      final text = src.readAsStringSync();
      expect(text, contains('is AuthException'));
      expect(text, contains('error.message'),
          reason: 'It must return the provider-supplied human-readable '
              'message, not a string this repository invented.');
    });
  });

  group('A-G4 no screen may present invented data as the user\'s own', () {
    /// `chat_screen.dart` displayed four hardcoded messages as the member's
    /// real coach conversation whenever the thread was empty or could not be
    /// created — including one attributed to the member themselves ("A bit sore
    /// but in a good way!..."). The screen already had the correct empty state;
    /// the fabricated fallback was the only thing hiding it.
    ///
    /// This guard is narrow on purpose. It pins the specific fabrication that
    /// shipped, rather than trying to define "fake data" in general — a broad
    /// rule would have to be weakened the first time a legitimate placeholder
    /// appeared, and a guard that gets weakened protects nothing.
    test('no presentation file calls getSampleMessages()', () {
      final offenders = <String>[];
      for (final file in presentationFiles) {
        for (final (i, line) in file.readAsLinesSync().indexed) {
          final code = line.split('//').first; // comments may name it
          if (code.contains('getSampleMessages')) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'A screen is substituting invented messages for real data:\n  '
            '${offenders.join('\n  ')}',
      );
    });

    test('the chat screen distinguishes failure from emptiness', () {
      final src = File(
        'lib/features/messaging/presentation/chat_screen.dart',
      ).readAsStringSync();

      expect(src, contains('_loadFailed'),
          reason: 'A thread that could not be reached is not an empty thread. '
              'Collapsing the two is the error-to-empty defect recorded as '
              'F-15 in docs/QA_EVIDENCE.md.');
      expect(src, contains("Start the conversation!"),
          reason: 'The genuine empty state must remain reachable.');
    });
  });

  group('A-G5 a failed load must not be rendered as a real figure', () {
    /// `train_hub_screen.dart` rendered `error: (_, __) => '0'` for STREAK,
    /// THIS WEEK and TOTAL. A member whose stats failed to load was told their
    /// streak was zero — a specific, wrong, and discouraging claim about their
    /// own training, produced by the app failing to ask.
    ///
    /// The same widget's DONE RATE tile already used `'—'` for that case, so
    /// the repair reused the file's own placeholder rather than inventing copy.
    ///
    /// Deliberately narrow: this guards the numeric-stat shape only. The wider
    /// error→empty collapse across eight screens (F-15) needs product copy that
    /// the design package does not supply, and is an owner decision — a guard
    /// that tried to cover it would have to be weakened to pass.
    test('no AsyncValue error branch returns a bare numeral', () {
      final offenders = <String>[];
      // `error: (_, __) => '0'` / `=> '0%'` / `=> 0` — a figure invented from a
      // failure. Whitespace-tolerant.
      final fabricated = RegExp(
        r"""error\s*:\s*\([^)]*\)\s*=>\s*'?-?\d+%?'?\s*[,)]""",
      );
      for (final file in presentationFiles) {
        for (final (i, line) in file.readAsLinesSync().indexed) {
          final code = line.split('//').first;
          if (fabricated.hasMatch(code)) offenders.add('${file.path}:${i + 1}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'A failed request is being displayed as a real measurement. '
            "Use the screen's own no-figure placeholder instead:\n  "
            '${offenders.join('\n  ')}',
      );
    });

    test('train_hub keeps its four stat tiles on the placeholder', () {
      final src = File(
        'lib/features/workout/presentation/train_hub_screen.dart',
      ).readAsStringSync();
      expect(
        RegExp(r"error: \(_, __\) => '—'").allMatches(src).length,
        4,
        reason: 'STREAK, THIS WEEK, TOTAL and DONE RATE must all show "—" when '
            'their load fails.',
      );
    });
  });

  group('A-G3 the app ships under its product name, on both platforms', () {
    /// Found at runtime: the first thing Android showed a new user was
    /// "Allow circle_fitness to send you notifications?" — the Flutter project
    /// directory name, in a system dialog. On Android `android:label` is also
    /// the launcher name, the app-drawer name and the Settings entry.
    ///
    /// The platforms had drifted apart too: iOS declared "Circle Fitness"
    /// while Android declared "circle_fitness", and neither was the product's
    /// name. Owner decision 2026-09-22: **12Circle Fitness**, both platforms.
    const expected = '12Circle Fitness';

    test('android:label is the product name', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      final m =
          RegExp(r'android:label="([^"]*)"').firstMatch(manifest);
      expect(m, isNotNull, reason: '<application> must declare android:label.');
      expect(
        m!.group(1),
        expected,
        reason: 'android:label is the launcher, Settings and permission-dialog '
            'name. It must never be the project directory name.',
      );
    });

    test('iOS CFBundleDisplayName matches, so the platforms cannot drift', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final m = RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>',
      ).firstMatch(plist);
      expect(m, isNotNull);
      expect(
        m!.group(1),
        expected,
        reason: 'iOS shipped "Circle Fitness" while Android shipped '
            '"circle_fitness". One product, one name.',
      );
    });
  });

  group('H-D1 the private-palette population must not grow', () {
    /// Three palettes ship concurrently — the Helix brand tier, a legacy
    /// `AppColors`, and a per-screen private palette in each file below. That
    /// is the measured state, and resolving it is D-2's owner decision.
    ///
    /// This guard does not judge the 20. It fails only on the 21st, so the
    /// decision can be taken deliberately rather than overtaken by drift.
    ///
    /// If a file is legitimately removed from this list — because it adopted
    /// the semantic tokens — delete its entry. The count is a ceiling, not a
    /// quota, and the test says so by asserting a subset rather than equality.
    const known = <String>{
      'insights_screen.dart',
      'settings_screen.dart',
      'home_screen.dart',
      'progress_screen.dart',
      'notifications_screen.dart',
      'events_screen.dart',
      'activity_screen.dart',
      'auth_design.dart',
      'dashboard_screen.dart',
      'directory_screen.dart',
      'profile_screen.dart',
      'checkin_screen.dart',
      'exercise_database_screen.dart',
      'exercise_detail_screen.dart',
      'create_exercise_screen.dart',
      'workout_list_screen.dart',
      'workout_history_screen.dart',
      'train_hub_screen.dart',
      'exercise_library_screen.dart',
      'workout_detail_screen.dart',
    };

    test('no NEW file declares a private colour palette class', () {
      // A private palette is a private class whose body is (almost) entirely
      // colour constants — the `class _C {}` / `class _S {}` / `class
      // AuthColors {}` shape the sweep found.
      final palette = RegExp(
        r'class\s+(_?[A-Z]\w*)\s*\{[^}]*static\s+const\s+(?:Color|c\w*)\s',
        dotAll: true,
      );

      final found = <String>{};
      for (final file in presentationFiles) {
        final source = file.readAsStringSync();
        if (!palette.hasMatch(source)) continue;
        if (!source.contains(RegExp(r'Color\(0x[0-9a-fA-F]{8}\)'))) continue;
        found.add(file.path.split('/').last);
      }

      final added = found.difference(known);
      expect(
        added,
        isEmpty,
        reason:
            'New private colour palette(s) introduced. The presentation layer '
            'already carries ${known.length} of these plus a legacy AppColors, '
            'against a semantic contract that says components consume only '
            'semantic tokens (see docs/MOBILE_QA_SWEEP_2026-09-22.md §4). '
            'Adding another widens a gap that is already an open owner '
            'decision:\n  ${added.join('\n  ')}',
      );
    });
  });
}
