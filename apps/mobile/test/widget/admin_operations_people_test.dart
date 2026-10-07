import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/features/admin/domain/admin_metrics.dart';
import 'package:circle_fitness/features/admin/domain/admin_provider.dart';
import 'package:circle_fitness/features/admin/domain/admin_trust.dart';
import 'package:circle_fitness/features/admin/presentation/admin_operations_screen.dart';
import 'package:circle_fitness/features/admin/presentation/admin_people_screen.dart';

/// V5 §185 — P5 · Operations and People. Both pages are ListViews, so the harness uses a
/// tall surface to build every section rather than relaxing the finders (§183.3).
Future<void> _pump(WidgetTester t, Widget screen, List<Override> o) async {
  await t.binding.setSurfaceSize(const Size(500, 4000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(ProviderScope(
    overrides: o,
    child: MaterialApp(home: screen),
  ));
  await t.pump();
}

final _denied = <Override>[
  adminReleaseStatusProvider.overrideWith((_) async => null),
  adminWearableConnectionsProvider.overrideWith((_) async => null),
  adminSecurityEventsProvider.overrideWith((_) async => null),
  adminUserOverviewProvider.overrideWith((_) async => null),
  adminUserDirectoryProvider.overrideWith((_) async => null),
];

String _allText(WidgetTester t) =>
    t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join(' | ');

void main() {
  group('Operations', () {
    testWidgets('the four published sections are present, in order', (t) async {
      await _pump(t, const AdminOperationsScreen(), _denied);
      final text = _allText(t);
      for (final s in ['OVERVIEW', 'RELEASES', 'INTEGRATIONS', 'SYSTEM EVENTS']) {
        expect(text.contains(s), isTrue, reason: 'missing $s in: $text');
      }
    });

    testWidgets('no capability means every area says so and no figure appears',
        (t) async {
      await _pump(t, const AdminOperationsScreen(), _denied);
      expect(find.text('Not available to your role'), findsWidgets);
      expect(RegExp(r'\b\d').hasMatch(_allText(t)), isFalse);
    });

    testWidgets('an authorized operator with NOTHING recorded sees the A11 state and the '
        'reason — the registry is empty because CI ingestion is gated, not broken',
        (t) async {
      await _pump(t, const AdminOperationsScreen(), [
        ..._denied,
        adminReleaseStatusProvider
            .overrideWith((_) async => AdminReleaseStatus.fromRow(const {})),
      ]);
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.textContaining('gated on P10'), findsOneWidget);
    });

    testWidgets('a recorded disagreement keeps the two verdicts SEPARATE, with no third '
        'combined verdict anywhere — METRIC-11 Option 3', (t) async {
      await _pump(t, const AdminOperationsScreen(), [
        ..._denied,
        adminReleaseStatusProvider.overrideWith((_) async =>
            AdminReleaseStatus.fromRow(const {
              'release_version': '4.2.0',
              'environment': 'staging',
              'ci_status': 'Passing',
              'ci_source': 'run 1',
              'ci_recorded_at': '2026-10-07T00:00:00Z',
              'gate_verdict': 'FAIL',
              'gates_pass': 5,
              'gates_partial': 2,
              'gates_fail': 8,
              'gates_total': 15,
              'gate_source': 'RELEASE_GATES.md',
              'gate_recorded_at': '2026-10-07T00:00:00Z',
            })),
      ]);
      expect(find.text('Passing'), findsOneWidget);
      expect(find.text('FAIL'), findsOneWidget);
      expect(find.text('5 pass · 2 partial · 8 fail of 15'), findsOneWidget);
      final text = _allText(t);
      for (final forbidden in ['BLOCKED', 'Releasable', 'Not releasable', 'Overall']) {
        expect(text.contains(forbidden), isFalse,
            reason: 'must not synthesise "$forbidden": $text');
      }
    });

    testWidgets('integrations shows connections and states that health waits on PD-G01',
        (t) async {
      await _pump(t, const AdminOperationsScreen(), [
        ..._denied,
        adminWearableConnectionsProvider.overrideWith((_) async =>
            AdminWearableConnections.fromRows(const [
              {'provider': 'whoop', 'connected': true},
            ])),
      ]);
      expect(find.textContaining('waits on PD-G01'), findsOneWidget);
      for (final label in ['Latency', 'Sync status', 'Integration health']) {
        expect(find.text(label), findsNothing);
      }
    });

    testWidgets('system events states A13·1, because this projection excludes the '
        "reader's own admin actions too", (t) async {
      await _pump(t, const AdminOperationsScreen(), [
        ..._denied,
        adminSecurityEventsProvider.overrideWith((_) async => [
              AdminAuditEventStub.adminAction(),
              AdminAuditEventStub.auditRead(),
            ]),
      ]);
      expect(find.text('Admin actions'), findsOneWidget);
      expect(find.text('Audit reads'), findsOneWidget);
      expect(find.textContaining('excluded from this log'), findsOneWidget);
    });
  });

  group('People', () {
    testWidgets('the five published sections are present, in order', (t) async {
      await _pump(t, const AdminPeopleScreen(), _denied);
      final text = _allText(t);
      for (final s in ['USERS', 'COACHES', 'CLIENTS', 'WELLNESS PARTNERS',
                       'STATE SYSTEM']) {
        expect(text.contains(s), isTrue, reason: 'missing $s in: $text');
      }
    });

    testWidgets('no capability means every area says so and no figure appears',
        (t) async {
      await _pump(t, const AdminPeopleScreen(), _denied);
      expect(find.text('Not available to your role'), findsWidgets);
      expect(RegExp(r'\b\d').hasMatch(_allText(t)), isFalse);
    });

    testWidgets('METRIC-05 · partners show a TOTAL ONLY, with no approval sub-count',
        (t) async {
      await _pump(t, const AdminPeopleScreen(), [
        ..._denied,
        adminUserOverviewProvider.overrideWith((_) async =>
            AdminUserOverview.fromRow(const {
              'users_total': 640,
              'clients_total': 500,
              'coaches_total': 135,
              'vendors_total': 0,
              'coaches_active_this_month': 2,
              'coaches_no_client_this_month': 133,
              'age_18_30': 1,
              'age_30_45': 1,
              'age_45_60': 0,
              'age_unknown': 638,
              'age_out_of_range': 0,
            })),
      ]);
      expect(find.text('Partners'), findsOneWidget);
      expect(find.text('None'), findsWidgets);
      // ASSERTED AS LABELLED READINGS, NOT AS PROSE. A sweep for "approval state" fires
      // on the card's own footnote, which says approval states are NOT shown — the third
      // time in this programme that a "must not mention X" assertion caught the sentence
      // explaining that X is absent (§184.3 for 'latency'). The property is that no
      // approval figure is DISPLAYED, and a tile label is an exact string.
      for (final label in ['Awaiting approval', 'Approval state', 'Pending approval',
                           'Approved', 'Onboarding state']) {
        expect(find.text(label), findsNothing,
            reason: 'METRIC-05 is "total only" — no "$label" reading may appear');
      }
      // METRIC-17's reconciliation row is hidden when empty, never shown as a bucket.
      expect(find.text('Outside the approved buckets'), findsNothing);
    });

    testWidgets('METRIC-03 · the coach partition is rendered as the design requires',
        (t) async {
      await _pump(t, const AdminPeopleScreen(), [
        ..._denied,
        adminUserOverviewProvider.overrideWith((_) async =>
            AdminUserOverview.fromRow(const {
              'coaches_total': 164,
              'coaches_active_this_month': 141,
              'coaches_no_client_this_month': 23,
            })),
      ]);
      expect(find.text('164'), findsOneWidget);
      expect(find.text('141'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('the three unbuilt requirements are STATED, not left blank', (t) async {
      // AUTHORIZED, because two of the three statements live beside the data they
      // qualify. To an operator who cannot see the area at all, "last active is not
      // shown" is noise — the statements explain what an otherwise-populated card omits.
      await _pump(t, const AdminPeopleScreen(), [
        ..._denied,
        adminUserOverviewProvider.overrideWith((_) async =>
            AdminUserOverview.fromRow(const {
              'users_total': 640,
              'coaches_total': 164,
              'vendors_total': 0,
              'coaches_active_this_month': 141,
              'coaches_no_client_this_month': 23,
            })),
      ]);
      final text = _allText(t);
      expect(text.contains('"Last active" is not shown'), isTrue,
          reason: 'the open population question is stated: $text');
      expect(text.contains('Coach verification is not shown'), isTrue,
          reason: 'no verification state exists in the schema, and that is said');
      expect(text.contains('Total only.'), isTrue,
          reason: "METRIC-05's ruling is stated beside the figure");
    });

    testWidgets('the account list shows the role and onboarding, and never relabels it '
        '"status" — no such state machine exists', (t) async {
      await _pump(t, const AdminPeopleScreen(), [
        ..._denied,
        adminUserDirectoryProvider.overrideWith((_) async => [
              AdminUserDirectoryEntry.fromRow(const {
                'id': 'u1',
                'first_name': 'Probe',
                'last_name': 'Member',
                'email': 'probe@qa.invalid',
                'role': 'client',
                'membership_tier': 'core',
                'onboarding_complete': false,
              }),
            ]),
      ]);
      expect(find.text('Probe Member'), findsOneWidget);
      expect(find.textContaining('client · core · onboarding incomplete'), findsOneWidget);
    });
  });
}

/// Minimal fixtures so these assertions do not depend on the Trust test's file.
abstract final class AdminAuditEventStub {
  static AdminAuditEvent adminAction() => _ev('admin_action');
  static AdminAuditEvent auditRead() => _ev('audit_read');
  static AdminAuditEvent _ev(String c) => AdminAuditEvent.fromRow({
        'id': 'e-\$c',
        'action': c,
        'occurred_at': '2026-10-07T03:00:00Z',
        'outcome': 'success',
        'category': c,
      });
}
