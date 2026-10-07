import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/features/admin/domain/admin_metrics.dart';
import 'package:circle_fitness/features/admin/domain/admin_provider.dart';
import 'package:circle_fitness/features/admin/presentation/admin_ecosystem_screen.dart';

/// V5 §184 — P5 · Ecosystem. The page is a ListView, so the harness uses a tall surface
/// to build every section (§183.3) rather than relaxing the finders.
Future<void> _pump(WidgetTester t, List<Override> overrides) async {
  await t.binding.setSurfaceSize(const Size(500, 4000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: AdminEcosystemScreen()),
  ));
  await t.pump();
}

final _denied = <Override>[
  adminCommunityOverviewProvider.overrideWith((_) async => null),
  adminEventsOverviewProvider.overrideWith((_) async => null),
  adminTrainingOverviewProvider.overrideWith((_) async => null),
  adminRevenueOverviewProvider.overrideWith((_) async => null),
  adminWearableConnectionsProvider.overrideWith((_) async => null),
];

String _allText(WidgetTester t) =>
    t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join(' | ');

void main() {
  testWidgets('the six published sections are present, in the published order', (t) async {
    await _pump(t, _denied);
    final text = _allText(t);
    for (final s in ['OVERVIEW', 'COMMUNITY', 'EVENTS', 'TRAINING', 'MONETIZATION',
                     'WEARABLES']) {
      expect(text.contains(s), isTrue, reason: 'missing section $s in: $text');
    }
  });

  testWidgets('an operator with no capability is told so per area, and sees no figure',
      (t) async {
    await _pump(t, _denied);
    expect(find.text('Not available to your role'), findsWidgets);
    final text = _allText(t);
    expect(RegExp(r'\b\d').hasMatch(text), isFalse, reason: text);
  });

  testWidgets('pods and groups are reported separately — METRIC-13 keeps them distinct',
      (t) async {
    await _pump(t, [
      ..._denied,
      adminCommunityOverviewProvider.overrideWith((_) async =>
          AdminCommunityOverview.fromRow(const {
            'pods_total': 7,
            'pods_active': 5,
            'community_groups_total': 3,
            'posts_total': 120,
            'posts_visible': 118,
            'reports_open': 0,
          })),
    ]);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    // The moderation queue's zero uses the design's own wording.
    expect(find.text('none open'), findsOneWidget);
  });

  testWidgets('attendance with nothing to divide renders an A11 state, never 0%',
      (t) async {
    await _pump(t, [
      ..._denied,
      adminEventsOverviewProvider.overrideWith((_) async =>
          AdminEventsOverview.fromRow(const {
            'events_total': 3,
            'event_registrations_total': 0,
            'event_registrations_attended': 0,
            'event_attendance_rate_pct': null,
            'event_registrations_30d': 0,
          })),
    ]);
    expect(find.text('Attendance rate'), findsOneWidget);
    expect(find.text('Not recorded'), findsWidgets);
    expect(find.text('0.0%'), findsNothing);
  });

  testWidgets('training shows counts and states that NO completion rate is derived',
      (t) async {
    await _pump(t, [
      ..._denied,
      adminTrainingOverviewProvider.overrideWith((_) async =>
          AdminTrainingOverview.fromRow(const {
            'programs_total': 12,
            'workouts_total': 90,
            'sessions_total': 9,
            'logs_total': 4,
          })),
    ]);
    expect(find.text('12'), findsWidgets);
    expect(find.textContaining('No completion rate is derived'), findsOneWidget);
    // No invented percentage anywhere in the training card.
    expect(find.textContaining(RegExp(r'\d+(\.\d+)?% *completion')), findsNothing);
  });

  group('wearables · the connection half only', () {
    testWidgets('connections are counted per provider and the total agrees', (t) async {
      await _pump(t, [
        ..._denied,
        adminWearableConnectionsProvider.overrideWith((_) async =>
            AdminWearableConnections.fromRows(const [
              {'provider': 'whoop', 'connected': true},
              {'provider': 'whoop', 'connected': true},
              {'provider': 'garmin', 'connected': true},
              {'provider': 'strava', 'connected': false},
            ])),
      ]);
      expect(find.text('whoop'), findsOneWidget);
      expect(find.text('garmin'), findsOneWidget);
      // A disconnected row is not a connection.
      expect(find.text('strava'), findsNothing);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('an unrecognised provider is still counted — provider has no CHECK, so '
        'dropping it would understate connections', (t) async {
      final m = AdminWearableConnections.fromRows(const [
        {'provider': null, 'connected': true},
        {'provider': 'whoop', 'connected': true},
      ]);
      expect(m.connectedTotal, 2);
      expect(m.byProvider['unrecognised'], 1);
    });

    testWidgets('the card STATES that sync health is absent by ruling, so the gap is not '
        'read as an oversight', (t) async {
      await _pump(t, [
        ..._denied,
        adminWearableConnectionsProvider
            .overrideWith((_) async => AdminWearableConnections.fromRows(const [])),
      ]);
      expect(find.textContaining('wait on PD-G01'), findsOneWidget);
      // THE PROPERTY IS THAT NO HEALTH FIGURE IS SHOWN — not that the words never
      // appear. A substring sweep for 'latency' fired on the very footnote that says
      // latency is absent, which is the assertion being wrong rather than the card. So
      // this checks for a LABELLED READING instead: a tile label is an exact string, and
      // an ingestion-health tile would have to carry one.
      for (final label in ['Latency', 'Sync status', 'Last sync', 'Ingestion errors',
                           'Sync health']) {
        expect(find.text(label), findsNothing,
            reason: 'no "$label" reading may be shown while WI-13 waits on PD-G01');
      }
    });
  });

  testWidgets('monetization shows the recorded split and never derives it', (t) async {
    await _pump(t, [
      ..._denied,
      adminRevenueOverviewProvider.overrideWith((_) async =>
          AdminRevenueOverview.fromRow(const {
            'gross_coaching_cents': 13000,
            'platform_commission_cents': 500,
            'net_platform_cents': 12500,
            'source_currency': 'usd',
            'commission_rate_missing': 2,
            'coach_payout_cents': 0,
            'platform_fee_cents': 0,
            'payout_missing': 3,
          })),
    ]);
    expect(find.text('USD 130.00'), findsOneWidget);
    expect(find.text('Paid to coaches'), findsOneWidget);
    expect(find.text('USD 0.00'), findsWidgets);
    expect(find.text('Payments with no recorded split'), findsOneWidget);
    expect(find.text('Payments with no recorded rate'), findsOneWidget);
  });
}
