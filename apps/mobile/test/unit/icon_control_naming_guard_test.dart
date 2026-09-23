import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A-G8 — the unnamed icon-only control population must not grow.
///
/// ── THE DEFECT ─────────────────────────────────────────────────────────────
/// A tappable whose entire content is an `Icon` — a back arrow, a close cross,
/// a pencil, a bell — reports to the accessibility tree with **no name**. A
/// screen reader announces nothing at all. This was measured on-device twice:
/// the password toggle (19.8 × 20.2 dp, unlabelled) and the three top-bar
/// controls (38 × 38, unlabelled). Both are now fixed with the design's own
/// wording.
///
/// A repository-wide scan found **56 more across 36 files**.
///
/// ── WHY A RATCHET AND NOT A FIX ────────────────────────────────────────────
/// Naming a control is product copy. The authoritative package supplies the
/// vocabulary for the controls it draws — "Back", "More", "Directory",
/// "Messages", "Notifications", "History", "Exercise library", "Show password"
/// — and those have been applied. It does not supply names for every icon in
/// screens it does not draw, and inventing 56 strings would be exactly the
/// fabrication the brief forbids. Recorded as F-22 / OD-8 instead.
///
/// So this guard holds the line where it sits. It fails on the 57th, which is
/// the only thing that can be asserted honestly today.
///
/// ── WHY IT DOES NOT COPY EC-G5'S MISTAKE ───────────────────────────────────
/// `QA_CLOSURE_STANDARD` §4 records that EC-G5 "counts `catch` blocks" while
/// the defect it targets has no `catch` in it, so ~150 sites are invisible to
/// it. This guard matches on the *shape that actually reports unlabelled* — a
/// tappable whose subtree has an Icon and no Text, tooltip or Semantics —
/// rather than on a keyword that happens to appear nearby.
void main() {
  /// The population as measured on 2026-09-23, after FIT-001's three top-bar
  /// controls were named. Lower this number when sites are fixed; never raise
  /// it. A rise means a new unreachable control shipped.
  const baseline = 56;

  List<({String file, int count})> scan() {
    final files = <File>[
      ...Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && f.path.contains('/presentation/')),
      ...Directory('lib/core/widgets')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
    ];

    final tappable = RegExp(r'(GestureDetector|InkWell|InkResponse)\(');
    final out = <({String file, int count})>[];

    for (final f in files) {
      final src = f.readAsStringSync();
      var n = 0;
      for (final m in tappable.allMatches(src)) {
        final end = (m.start + 420).clamp(0, src.length);
        final w = src.substring(m.start, end);
        if (!w.contains('onTap')) continue;
        final hasIcon = RegExp(r'\bIcon\(|Icons\.').hasMatch(w);
        final hasText = RegExp(r'\bText\(|child: Text|label:').hasMatch(w);
        final hasName = RegExp(r'Semantics\(|tooltip:|semanticLabel').hasMatch(w);
        if (hasIcon && !hasText && !hasName) n++;
      }
      if (n > 0) out.add((file: f.path, count: n));
    }
    return out;
  }

  test('A-G8 unnamed icon-only controls are at or below the recorded baseline', () {
    final found = scan();
    final total = found.fold<int>(0, (a, b) => a + b.count);

    final worst = (found.toList()..sort((a, b) => b.count.compareTo(a.count)))
        .take(8)
        .map((e) => '  ${e.count.toString().padLeft(3)}  ${e.file}')
        .join('\n');

    expect(
      total,
      lessThanOrEqualTo(baseline),
      reason:
          'A new icon-only control shipped with no accessible name — a screen '
          'reader announces nothing for it.\n'
          'Found $total across ${found.length} files (baseline $baseline).\n'
          'Heaviest files:\n$worst\n\n'
          'Name it with the authoritative design\'s wording if the package '
          'draws the screen. If it does not, the name is product copy: record '
          'it under OD-8 rather than inventing one.',
    );
  });

  test('A-G8 the controls already fixed stay fixed', () {
    // These three were measured unlabelled on-device and named from FIT-001.
    final nav = File('lib/core/widgets/app_top_nav.dart').readAsStringSync();
    for (final label in ['Directory', 'Messages', 'Notifications']) {
      expect(nav, contains("label: '$label'"),
          reason: '$label was named from FIT-001 after being measured '
              'unlabelled on emulator-5554.');
    }
    // And the password toggle, measured at 19.8 x 20.2 dp with no name.
    final auth = File('lib/features/auth/presentation/widgets/auth_design.dart')
        .readAsStringSync();
    expect(auth, contains("'Show password'"));
    expect(auth, contains("'Hide password'"));
  });
}
