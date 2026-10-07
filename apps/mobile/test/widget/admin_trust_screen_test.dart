import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/core/observability/app_failure.dart';
import 'package:circle_fitness/features/admin/data/admin_trust_service.dart';
import 'package:circle_fitness/features/admin/domain/admin_metrics.dart';
import 'package:circle_fitness/features/admin/domain/admin_provider.dart';
import 'package:circle_fitness/features/admin/domain/admin_trust.dart';
import 'package:circle_fitness/features/admin/presentation/admin_tokens.dart';
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
  adminCanUpdateIncidentsProvider.overrideWith((_) async => false),
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

  group('incident resolution · the approved Resolve action, capability-gated', () {
    // §183 first shipped this page as read-only "by design rule", citing CONF-D5's
    // drawer footer. That was wrong about the PAGE: the approved Trust screen contains
    // Resolve, Investigate and "Assign, change status, add…", and `Read-only` is one of
    // the STATES designed for Trust — a state for a role that may view and not update.
    List<Override> withIncident({required bool canUpdate, String? resolution}) => [
          ..._denied,
          adminCanUpdateIncidentsProvider.overrideWith((_) async => canUpdate),
          adminIncidentsProvider.overrideWith((_) async => [
                AdminIncident.fromRow({
                  'id': 'i1',
                  'summary': '38 failed sign-ins',
                  'severity': 'Critical',
                  'scope': 'Security',
                  if (resolution != null) 'resolution': resolution,
                }),
              ]),
        ];

    testWidgets('a role WITHOUT Incidents·update gets no action and is told why — the '
        'approved read-only state, stated rather than inferred from a missing button',
        (t) async {
      await _pump(t, withIncident(canUpdate: false));
      expect(find.text('Resolve'), findsNothing);
      expect(find.textContaining('requires Incidents · update'), findsOneWidget);
    });

    testWidgets('a role WITH Incidents·update gets the action', (t) async {
      await _pump(t, withIncident(canUpdate: true));
      expect(find.text('Resolve'), findsOneWidget);
      expect(find.textContaining('requires Incidents · update'), findsNothing);
    });

    testWidgets('an ALREADY-resolved incident offers no action, so a resolution cannot '
        'be recorded twice', (t) async {
      await _pump(t, withIncident(canUpdate: true, resolution: 'rotated the key'));
      expect(find.text('Resolve'), findsNothing);
      expect(find.textContaining('resolved'), findsWidgets);
    });

    testWidgets('the action opens a CONFIRM dialog — the Interactions section requires '
        'one — and says the record cannot be undone from here', (t) async {
      await _pump(t, withIncident(canUpdate: true));
      await t.tap(find.text('Resolve'));
      await t.pumpAndSettle();
      expect(find.text('Record a resolution'), findsOneWidget);
      expect(find.textContaining('cannot be undone from this screen'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      // Cancel leaves nothing behind.
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Record a resolution'), findsNothing);
    });

    testWidgets('an EMPTY resolution is not submitted — the governed path rejects a blank '
        'and the dialog should not ask it to', (t) async {
      await _pump(t, withIncident(canUpdate: true));
      await t.tap(find.text('Resolve'));
      await t.pumpAndSettle();
      await t.tap(find.text('Record'));
      await t.pumpAndSettle();
      // No crash, no snackbar: the submit was simply not attempted.
      expect(find.textContaining('was not recorded'), findsNothing);
    });

    testWidgets('a REFUSED write is surfaced AND reported — the operator is told nothing '
        'was saved, and the raw exception goes to the sink rather than the screen',
        (t) async {
      final captured = <AppFailure>[];
      setFailureSink(captured.add);
      addTearDown(resetFailureSink);

      await _pump(t, [
        ...withIncident(canUpdate: true),
        // The service throws, exactly as the governed path does with 42501 when the
        // caller lacks Incidents·update. The RPC re-checks the capability itself, so the
        // client gate is convenience and this is the real boundary being refused.
        adminTrustServiceProvider.overrideWithValue(_RefusingTrustService()),
      ]);
      await t.tap(find.text('Resolve'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'rotated the key');
      await t.tap(find.text('Record'));
      await t.pumpAndSettle();

      // 1 · the operator is TOLD, and told that nothing was saved.
      expect(find.textContaining('was not recorded'), findsOneWidget);
      expect(find.textContaining('Nothing was saved'), findsOneWidget);
      // 2 · the raw exception is NOT on screen (ERR-G2).
      final text = _allText(t);
      expect(text.contains('42501'), isFalse, reason: 'raw error on screen: $text');
      expect(text.contains('PostgrestException'), isFalse);
      // 3 · but it IS diagnosable — the sink has it, with the incident it concerned.
      expect(captured, hasLength(1));
      expect(captured.single.origin, 'admin_trust.resolveIncident');
      expect(captured.single.error.toString(), contains('42501'));
      expect(captured.single.context?['incident_id'], 'i1');
    });

    testWidgets('the action meets the 44px touch target RESPONSIVE.md requires', (t) async {
      await _pump(t, withIncident(canUpdate: true));
      final box = t.getSize(find
          .ancestor(of: find.text('Resolve'), matching: find.byType(SizedBox))
          .first);
      expect(box.height, AdminDims.sizeControl);
    });
  });

  group('a capability check that FAILS is not a denial (EC-G8)', () {
    // The first version read the capability with `.valueOrNull ?? false`, so a FAILED
    // check rendered "Read-only: resolving an incident requires Incidents · update" —
    // telling an operator they lack a permission they may well hold. EC-G8 flagged it and
    // was right: on a provider that does I/O, `.valueOrNull` turns "could not load" into
    // the domain's empty value, which here is a denial.
    List<Override> capability(AsyncValue<bool> v) => [
          ..._denied,
          adminIncidentsProvider.overrideWith((_) async => [
                AdminIncident.fromRow(const {
                  'id': 'i1',
                  'summary': '38 failed sign-ins',
                  'severity': 'Critical',
                }),
              ]),
          if (v.hasError)
            adminCanUpdateIncidentsProvider
                .overrideWith((_) async => throw Exception('network'))
          else
            adminCanUpdateIncidentsProvider
                .overrideWith((_) async => v.requireValue),
        ];

    testWidgets('a FAILED check says so, and does NOT claim the permission is missing',
        (t) async {
      await _pump(t, capability(const AsyncError('x', StackTrace.empty)));
      expect(find.textContaining('could not be checked'), findsOneWidget);
      expect(find.textContaining('this is not a denial'), findsOneWidget);
      // The denial wording must be absent — that is the whole point.
      expect(find.textContaining('requires Incidents · update'), findsNothing);
      // And no action is offered on an unknown capability.
      expect(find.text('Resolve'), findsNothing);
    });

    testWidgets('a GENUINE false still renders the approved read-only state', (t) async {
      await _pump(t, capability(const AsyncData(false)));
      expect(find.textContaining('requires Incidents · update'), findsOneWidget);
      expect(find.textContaining('could not be checked'), findsNothing);
    });

    testWidgets('a GENUINE true still offers the action', (t) async {
      await _pump(t, capability(const AsyncData(true)));
      expect(find.text('Resolve'), findsOneWidget);
      expect(find.textContaining('could not be checked'), findsNothing);
    });
  });

  testWidgets('the Guardian section NAMES the figures the approved design asks for and no '
      'surface produces, rather than leaving blanks', (t) async {
    await _pump(t, [
      ..._denied,
      adminCanViewGuardianProvider.overrideWith((_) async => true),
      adminGuardianStateProvider.overrideWith((_) async =>
          AdminGuardianState.fromRow({'state': 'Active'})),
    ]);
    // The published section shows these; nothing in the schema produces them.
    expect(find.textContaining('evaluation-engine state'), findsOneWidget);
    expect(find.textContaining('median decision time'), findsOneWidget);
    expect(find.textContaining('agents without a policy'), findsOneWidget);
    // And none is estimated: no figure is presented under those names.
    for (final l in ['Median decision time', 'Agents without a policy',
                     'Evaluation engine', 'Last full evaluation']) {
      expect(find.text(l), findsNothing,
          reason: 'no "$l" reading may be shown — no surface produces it');
    }
  });

  testWidgets('the GUARDIAN remains read-only — A10 bars it from holding admin authority '
      'and nothing here re-states it', (t) async {
    await _pump(t, _denied);
    expect(find.textContaining('Nothing is changed from this screen'), findsWidgets);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    // No Guardian control: re-stating it goes through admin_set_guardian_state, gated
    // AI Guardian·manage, which this page never calls.
    for (final l in ['Disable Guardian', 'Enable Guardian', 'Set state']) {
      expect(find.text(l), findsNothing);
    }
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


/// Refuses the write the way the governed path does: `admin_update_incident_response` is
/// SECURITY DEFINER and raises `42501` itself when `Incidents·update` is absent, so the
/// client-side gate is convenience and this is the boundary that actually holds.
class _RefusingTrustService extends AdminTrustService {
  _RefusingTrustService() : super(client: null);

  @override
  Future<void> resolveIncident(String incidentId, String resolution) =>
      Future.error(Exception('42501: not authorized: Incidents/update is required'));
}
