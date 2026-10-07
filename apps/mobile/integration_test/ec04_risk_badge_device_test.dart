// EC-04 · the risk badge, measured on the device.
//
// The host-VM guard (`test/unit/risk_signal_guard_test.dart`, SEC-G6) proves the
// coercion is gone and that every risk `switch` matches `low` explicitly and falls back
// to an unassessed label. Three assertions cannot live there, and the third is the whole
// point of the fix:
//
//  * whether the badge survives the real font at a real device pixel ratio, rather than
//    Ahem's full-em squares (the F-24 class);
//  * whether "NOT ASSESSED" fits the pill it is drawn in without clipping;
//  * **whether a coach using a screen reader is told the assessment is absent.** The fix
//    distinguishes unassessed from low by COLOUR and by LABEL. Colour reaches nobody on
//    a screen reader, so if the label did not reach the platform accessibility tree the
//    defect would persist for exactly the users least able to notice it — and EC-04's
//    harm is a coach being told a client is low risk when nobody assessed them.
//
// NOTHING IS SIGNED IN AND NO BACKEND IS TOUCHED. `clientDetailProvider` is overridden
// with an in-memory profile, so this leaves no fixture behind and makes no claim about
// any real client's risk.
//
// It emits MARKER lines, and the harness that drives it
// (tool/negative_control/ec04_risk_badge_e2e.sh) refuses to report success unless they
// appear. Without that, a toolchain failure that never mounted the screen would exit
// non-zero for an unrelated reason — or worse, a future refactor could make the
// assertions vacuous and still pass. An end-to-end claim has to prove the driver
// actually reached the surface.
//
//   flutter test integration_test/ec04_risk_badge_device_test.dart \
//     -d linux --dart-define-from-file=dart_defines/qa.json

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:circle_fitness/features/coach/domain/coach_ecosystem_provider.dart';
import 'package:circle_fitness/features/dashboard/presentation/client_detail_screen.dart';

const _clientId = 'ec04-probe-client';

Map<String, dynamic> _profile({String? riskLevel}) => {
      'id': _clientId,
      'first_name': 'Probe',
      'last_name': 'Client',
      'email': 'ec04-probe@qa.invalid',
      'role': 'client',
      // THE FIELD UNDER TEST. `null` is the state EC-04 rendered as a green LOW RISK
      // badge: a PAR-Q that was never saved, or a profile read that simply failed.
      if (riskLevel != null) 'risk_level': riskLevel,
    };

Future<void> _mount(WidgetTester t, {String? riskLevel}) async {
  await t.pumpWidget(ProviderScope(
    overrides: [
      clientDetailProvider(_clientId)
          .overrideWith((ref) async => _profile(riskLevel: riskLevel)),
    ],
    child: const MaterialApp(
      home: ClientDetailScreen(clientId: _clientId, clientName: 'Probe Client'),
    ),
  ));
  // The screen fans out to several live providers; they are allowed to fail, which is
  // itself part of the case — EC-04's harm includes the read-failure path.
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an UNASSESSED client is labelled unassessed, not low risk — and the '
      'label reaches the accessibility tree', (t) async {
    final handle = t.ensureSemantics();
    await _mount(t);

    debugPrint('EC04-MARKER mounted=client_detail');

    // 1 · the visible label.
    expect(find.textContaining(RegExp('not assessed', caseSensitive: false)),
        findsWidgets,
        reason: 'the badge must say the assessment is absent');
    expect(find.textContaining(RegExp(r'low\s*risk', caseSensitive: false)),
        findsNothing,
        reason: 'an unassessed client must never be presented as low risk');

    // 2 · it is not clipped at the real font and dpr.
    final badge = find
        .textContaining(RegExp('not assessed', caseSensitive: false))
        .first;
    final size = t.getSize(badge);
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
    expect(badgeOverflowed(), isFalse,
        reason: 'the unassessed label must fit the pill it is drawn in');

    // 3 · THE ASSERTION THAT COLOUR CANNOT MAKE. A screen reader conveys no colour, so
    // the label is the only thing that distinguishes unassessed from low risk.
    final tree = t.binding.rootPipelineOwner.semanticsOwner!.rootSemanticsNode!;
    final labels = <String>[];
    void walk(SemanticsNode node) {
      final d = node.getSemanticsData();
      if (d.label.isNotEmpty) labels.add(d.label);
      node.visitChildren((c) { walk(c); return true; });
    }
    walk(tree);
    final joined = labels.join(' | ').toLowerCase();
    expect(joined.contains('not assessed'), isTrue,
        reason: 'a coach on a screen reader must be TOLD the assessment is absent. '
            'Found: $joined');
    expect(joined.contains('low risk'), isFalse,
        reason: 'the accessibility tree must not claim a low assessment: $joined');

    debugPrint('EC04-MARKER semantics=not_assessed');
    debugPrint('EC04-MARKER badge_size=${size.width.toStringAsFixed(1)}'
        'x${size.height.toStringAsFixed(1)}');

    handle.dispose();
  });

  testWidgets('an ASSESSED low-risk client is still labelled low risk, so the fix did '
      'not simply delete the state', (t) async {
    await _mount(t, riskLevel: 'low');
    expect(find.textContaining(RegExp(r'low\s*risk', caseSensitive: false)),
        findsWidgets);
    debugPrint('EC04-MARKER assessed_low=rendered');
  });

  testWidgets('a HIGH-risk client is unaffected', (t) async {
    await _mount(t, riskLevel: 'high');
    expect(find.textContaining(RegExp('high risk', caseSensitive: false)),
        findsWidgets);
    debugPrint('EC04-MARKER assessed_high=rendered');
  });
}

/// True when any render object reported an overflow during this frame. Flutter surfaces
/// overflow as an exception through the error reporter, which the harness records.
bool badgeOverflowed() {
  final e = TestWidgetsFlutterBinding.instance.takeException();
  if (e == null) return false;
  final s = e.toString();
  // Re-throw anything that is NOT an overflow: swallowing a real error here would make
  // this assertion a silent success.
  if (!s.contains('overflowed')) {
    throw StateError('unexpected exception while measuring the badge: $s');
  }
  return true;
}
