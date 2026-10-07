import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/features/admin/domain/admin_metrics.dart';
import 'package:circle_fitness/features/admin/domain/admin_provider.dart';
import 'package:circle_fitness/features/admin/domain/admin_trust.dart';
import 'package:circle_fitness/features/admin/presentation/admin_trust_screen.dart';

/// V5 §183 — P6 · Trust. The sections are the published ones; these tests cover the
/// three properties the page exists to keep, each of which this programme has already
/// paid for once elsewhere.
/// A TALL viewport, because the page is a ListView and a ListView builds lazily — the
/// first draft of this harness could not see the Audit or State-system sections at all
/// and read as "the A13 note is missing". The fix is to give the test enough surface to
/// build every section, NOT to relax the finders with `skipOffstage: false`, which would
/// assert against widgets a real operator never sees.
Future<void> _pump(WidgetTester t, List<Override> overrides) async {
  await t.binding.setSurfaceSize(const Size(500, 4000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: AdminTrustScreen()),
  ));
  await t.pump();
}

/// Everything denied, so each test overrides only what it is about.
final _denied = <Override>[
  adminGuardianStateProvider.overrideWith((_) async => null),
  adminCanViewGuardianProvider.overrideWith((_) async => false),
  adminGovernancePoliciesProvider.overrideWith((_) async => null),
  adminSecurityEventsProvider.overrideWith((_) async => null),
  adminIncidentsProvider.overrideWith((_) async => null),
  adminAuditEventsProvider.overrideWith((_) async => null),
];

String _allText(WidgetTester t) =>
    t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join(' | ');

AdminAuditEvent _event({
  String category = 'authentication',
  String? pseudonym = 'a1b2c3d4e5f6a7b8',
}) =>
    AdminAuditEvent.fromRow({
      'id': 'e1',
      'actor_id': '00000000-0000-0000-0000-00000000aaaa',
      'subject_pseudonym': pseudonym,
      'action': 'sign_in',
      'occurred_at': '2026-10-07T03:00:00Z',
      'outcome': 'success',
      'category': category,
      'actor_provenance': 'grounded',
      'correlation_id': 'c1',
    });

void main() {
  testWidgets('the six published sections are present, in the published order', (t) async {
    await _pump(t, _denied);
    final text = _allText(t);
    for (final s in ['OVERVIEW', 'AI GUARDIAN', 'SECURITY', 'INCIDENTS',
                     'AUDIT LOGS', 'STATE SYSTEM']) {
      expect(text.contains(s), isTrue, reason: 'missing section $s in: $text');
    }
  });

  testWidgets('an operator with no Trust capability is told so for every section, and '
      'sees no figure anywhere', (t) async {
    await _pump(t, _denied);
    expect(find.text('Not available to your role'), findsWidgets);
    final text = _allText(t);
    expect(RegExp(r'\b\d').hasMatch(text), isFalse,
        reason: 'no figure may reach an uncapable operator: $text');
  });

  group('the Guardian state is never guessed into something reassuring', () {
    testWidgets('AUTHORIZED but NOTHING RECORDED renders "Not recorded" — never '
        '"Active". guardian_state starts empty, and the most reassuring reading of '
        'missing data is exactly EC-04\'s defect on a safety control', (t) async {
      await _pump(t, [
        ..._denied,
        adminCanViewGuardianProvider.overrideWith((_) async => true),
        adminGuardianStateProvider.overrideWith((_) async => null),
      ]);
      expect(find.text('Not recorded'), findsWidgets);
      final text = _allText(t);
      expect(text.contains('Active'), isFalse,
          reason: 'an unrecorded Guardian must not read as running: $text');
    });

    testWidgets('NO CAPABILITY is a different state from NOTHING RECORDED', (t) async {
      await _pump(t, [
        ..._denied,
        adminCanViewGuardianProvider.overrideWith((_) async => false),
        adminGuardianStateProvider.overrideWith((_) async => null),
      ]);
      expect(find.text('Not available to your role'), findsWidgets);
    });

    testWidgets('a recorded state is shown as recorded', (t) async {
      await _pump(t, [
        ..._denied,
        adminCanViewGuardianProvider.overrideWith((_) async => true),
        adminGuardianStateProvider.overrideWith((_) async =>
            AdminGuardianState.fromRow(
                {'state': 'Monitoring', 'set_at': '2026-10-07T00:00:00Z'})),
      ]);
      expect(find.text('Monitoring'), findsWidgets);
    });

    testWidgets('a DISABLED Guardian shows the reason, because 169 requires one to '
        'disable — so a Disabled state with no reason is itself a finding', (t) async {
      await _pump(t, [
        ..._denied,
        adminCanViewGuardianProvider.overrideWith((_) async => true),
        adminGuardianStateProvider.overrideWith((_) async =>
            AdminGuardianState.fromRow({
              'state': 'Disabled',
              'reason': 'emergency disablement during incident 44',
              'set_at': '2026-10-07T00:00:00Z',
            })),
      ]);
      // A wrapping footnote, not a tile value — a disablement reason must not be
      // truncated, which is what a single-row tile would have done to it.
      expect(find.textContaining('Disabled because'), findsOneWidget);
      expect(find.textContaining('emergency disablement during incident 44'),
          findsOneWidget);
    });

    testWidgets('an UNRECOGNISED state is not treated as healthy', (t) async {
      final g = AdminGuardianState.fromRow({'state': 'Whatever'});
      expect(AdminTrustSummary.guardianIsHealthy(g), isNull,
          reason: 'a state outside A5 cannot be reported as healthy');
      expect(AdminTrustSummary.guardianIsHealthy(null), isNull);
      expect(
          AdminTrustSummary.guardianIsHealthy(
              AdminGuardianState.fromRow({'state': 'Active'})),
          isTrue);
      expect(
          AdminTrustSummary.guardianIsHealthy(
              AdminGuardianState.fromRow({'state': 'Disabled'})),
          isFalse);
    });
  });

  group('§19.3 · a pseudonym is rendered as a pseudonym and never resolved', () {
    testWidgets('the audit row shows the pseudonym, truncated and labelled as a '
        'subject — and no name, email or uuid of a subject appears', (t) async {
      await _pump(t, [
        ..._denied,
        adminAuditEventsProvider.overrideWith((_) async => [_event()]),
      ]);
      expect(find.textContaining('subject a1b2c3d4'), findsOneWidget);
      final text = _allText(t);
      expect(text.contains('@'), isFalse, reason: 'no email may appear: $text');
      // The FULL pseudonym is not printed either — it is truncated, so the rendered
      // string cannot be pasted back as a lookup key.
      expect(text.contains('a1b2c3d4e5f6a7b8'), isFalse,
          reason: 'the pseudonym is shown truncated, not whole: $text');
    });

    test('the model exposes no way to resolve a pseudonym', () {
      final e = _event();
      // Reading the public surface: a pseudonym and nothing derived from it. If a
      // `subjectId` or a resolve() were ever added, this test is where it is noticed.
      expect(e.subjectPseudonym, 'a1b2c3d4e5f6a7b8');
      expect(e.toString().contains('subjectId'), isFalse);
    });
  });

  testWidgets('A13·1 is STATED on the audit section, so absence is not read as evidence '
      'of absence', (t) async {
    await _pump(t, [
      ..._denied,
      adminAuditEventsProvider.overrideWith((_) async => [_event()]),
    ]);
    expect(find.text(AdminAuditEvent.a13Note), findsOneWidget);
    expect(find.textContaining('excluded from this log'), findsOneWidget);
  });

  testWidgets('an EMPTY audit log uses the design\'s zero copy and still states A13·1',
      (t) async {
    await _pump(t, [
      ..._denied,
      adminAuditEventsProvider.overrideWith((_) async => const <AdminAuditEvent>[]),
    ]);
    expect(find.text('none raised'), findsWidgets);
    expect(find.text(AdminAuditEvent.a13Note), findsOneWidget);
  });

  testWidgets('#sec-authz · authorization denials are counted separately from '
      'authentication events', (t) async {
    await _pump(t, [
      ..._denied,
      adminSecurityEventsProvider.overrideWith((_) async => [
            _event(category: 'authorization_denial'),
            _event(category: 'authorization_denial'),
            _event(category: 'authentication'),
          ]),
    ]);
    expect(find.text('Authorization denials'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Authentication events'), findsOneWidget);
  });

  testWidgets('the page is READ-ONLY — it states so, and carries no control that could '
      'change anything', (t) async {
    await _pump(t, _denied);
    expect(find.textContaining('Nothing is changed from this screen'), findsWidgets);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('B-4 holds: no withheld incident field can reach the screen', (t) async {
    await _pump(t, [
      ..._denied,
      adminIncidentsProvider.overrideWith((_) async => [
            AdminIncident.fromRow({
              'id': 'i1',
              'summary': '38 failed sign-ins',
              'severity': 'Critical',
              'scope': 'Security',
            })
          ]),
    ]);
    final text = _allText(t).toLowerCase();
    expect(text.contains('evidence and actor identity are withheld'), isTrue);
    expect(text.contains('actor_identity'), isFalse);
  });
}
