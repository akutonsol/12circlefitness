import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/features/admin/domain/admin_metrics.dart';
import 'package:circle_fitness/features/admin/domain/admin_provider.dart';
import 'package:circle_fitness/features/admin/presentation/admin_metrics_panel.dart';

/// V5 §166 — the panel's job is to render the right `A11` state, and the states it
/// must never confuse are: not authorized · not recorded · loading · error · a real
/// zero. Each of those is a different statement to an operator, and four of the five
/// are indistinguishable once something writes `?? 0`.
Future<void> _pump(WidgetTester t, List<Override> overrides) async {
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    // The panel is a Column and does NOT own scrolling — a panel composed into a
    // page should not, or two of them on one page fight for it. So the harness
    // supplies the scroll view, exactly as the hosting screen must. The first draft
    // put the panel in a fixed-height SizedBox and overflowed by 330px, which is a
    // defect in the harness rather than in the widget.
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: Size(420, 900)),
        child: SizedBox(
          width: 420,
          height: 900,
          child: SingleChildScrollView(child: AdminMetricsPanel()),
        ),
      ),
    ),
  ));
  await t.pump();
}

String _allText(WidgetTester t) =>
    t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join(' | ');

void main() {
  // Every provider resolved to null = "no capability for this area".
  final allDenied = [
    adminActivityOverviewProvider.overrideWith((_) async => null),
    adminUserOverviewProvider.overrideWith((_) async => null),
    adminEventsOverviewProvider.overrideWith((_) async => null),
    adminCommunityOverviewProvider.overrideWith((_) async => null),
    adminRevenueOverviewProvider.overrideWith((_) async => null),
    adminReleaseStatusProvider.overrideWith((_) async => null),
  // Overridden EXPLICITLY, not left to chance. Without it the attention queue
  // reaches for an uninitialised Supabase client and lands in the error state,
  // so these tests would pass for an accidental reason rather than a stated one.
    adminIncidentsProvider.overrideWith((_) async => null),
  ];

  testWidgets('an unauthorized operator sees WHY each area is empty, and no figure '
      'anywhere — the card does not vanish and does not show zeros', (t) async {
    await _pump(t, allDenied);
    expect(find.text('Not available to your role'), findsWidgets);
    final text = _allText(t);
    expect(RegExp(r'\b\d').hasMatch(text), isFalse,
        reason: 'no figure may be rendered to an unauthorized operator: $text');
  });

  testWidgets('LOADING is its own state — a card mid-flight must not read as a '
      'platform with no activity', (t) async {
    // A provider that never completes stays in the loading state. A Completer is
    // used rather than Future.delayed, which leaves a pending Timer and makes the
    // test fail on teardown for a reason unrelated to what it asserts.
    final never = Completer<AdminActivityOverview?>();
    addTearDown(() => never.complete(null));
    await _pump(t, [
      ...allDenied,
      adminActivityOverviewProvider.overrideWith((_) => never.future),
    ]);
    expect(find.text('Loading…'), findsWidgets);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('ERROR is its own state, and is NOT reported as a permission boundary '
      '— a dropped connection is not an authorization outcome', (t) async {
    await _pump(t, [
      ...allDenied,
      adminEventsOverviewProvider
          .overrideWith((_) async => throw Exception('network')),
    ]);
    expect(find.text('Unavailable'), findsWidgets);
  });

  group('METRIC-02 · the authorization split reaches the screen', () {
    testWidgets('a Users-only operator sees Session figures and is told the sign-in '
        'basis is not theirs — not that it is zero', (t) async {
      await _pump(t, [
        ...allDenied,
        adminActivityOverviewProvider.overrideWith((_) async =>
            AdminActivityOverview.fromRow(const {
              'session_users_today': 4,
              'session_users_week': 11,
              'session_users_month': 26,
              'session_users_prev_month': 19,
              'signin_users_today': null,
              'signin_users_week': null,
              'signin_users_month': null,
              'signin_users_prev_month': null,
              'sessions_today': 9,
              'sessions_month': 140,
              'day_start': '2026-10-07T00:00:00Z',
              'week_start': '2026-10-05T00:00:00Z',
              'month_start': '2026-10-01T00:00:00Z',
              'window_timezone': 'UTC',
            })),
      ]);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(find.text('+7'), findsOneWidget); // 26 - 19
      // SESSIONS ARE NOT USERS. 4 members were active today and they recorded 9
      // Sessions between them; the design shows both and the card must not conflate
      // them. If the panel rendered one for the other, "9" would be absent.
      expect(find.text('Daily sessions'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      // The window is DISCLOSED, because the data contract leaves the timezone
      // unsettled and an invisible window is an assumption the reader cannot check.
      expect(find.textContaining('Day begins 2026-10-07'), findsOneWidget);
      expect(find.textContaining('UTC'), findsOneWidget);
      // The three sign-in rows must each say so.
      expect(find.text('Active today · Sign-ins'), findsOneWidget);
      expect(find.text('Not available to your role'), findsWidgets);
    });
  });

  group('METRIC-17 · the reconciliation row is not a fifth bucket', () {
    AdminUserOverview users({required int outOfRange}) =>
        AdminUserOverview.fromRow({
          'users_total': 100,
          'coaches_total': 10,
          'vendors_total': 0,
          'coaches_active_this_month': 3,
          'coaches_no_client_this_month': 7,
          'age_18_30': 40,
          'age_30_45': 25,
          'age_45_60': 10,
          'age_unknown': 25 - outOfRange,
          'age_out_of_range': outOfRange,
        });

    testWidgets('with nobody outside the approved buckets, no extra row appears',
        (t) async {
      await _pump(t, [
        ...allDenied,
        adminUserOverviewProvider.overrideWith((_) async => users(outOfRange: 0)),
      ]);
      expect(find.text('Outside the approved buckets'), findsNothing);
      expect(find.text('Age unknown'), findsOneWidget);
    });

    testWidgets('with genuine 60+ records the row DOES appear, labelled as what it '
        'is — hiding it would make the panel misstate its own total, and inventing '
        'a 60+ bucket is forbidden', (t) async {
      await _pump(t, [
        ...allDenied,
        adminUserOverviewProvider.overrideWith((_) async => users(outOfRange: 5)),
      ]);
      expect(find.text('Outside the approved buckets'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.textContaining('60+'), findsNothing);
    });

    testWidgets('METRIC-05 shows a total only — there is no approval sub-count',
        (t) async {
      await _pump(t, [
        ...allDenied,
        adminUserOverviewProvider.overrideWith((_) async => users(outOfRange: 0)),
      ]);
      expect(find.text('Wellness partners'), findsOneWidget);
      expect(find.textContaining('awaiting'), findsNothing);
      expect(find.textContaining('approval'), findsNothing);
    });
  });

  group('METRIC-14 · a missing rate is not 0%', () {
    testWidgets('no registrations yields the not-recorded state, never "0.0%"',
        (t) async {
      await _pump(t, [
        ...allDenied,
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

    testWidgets('a measured rate renders, and a measured zero count uses the '
        'design\'s wording', (t) async {
      await _pump(t, [
        ...allDenied,
        adminEventsOverviewProvider.overrideWith((_) async =>
            AdminEventsOverview.fromRow(const {
              'events_total': 3,
              'event_registrations_total': 4,
              'event_registrations_attended': 0,
              'event_attendance_rate_pct': 0,
              'event_registrations_30d': 2,
            })),
      ]);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('None'), findsWidgets); // attended = 0
    });
  });

  group('METRIC-06 · incompleteness is disclosed, FX is never approximated', () {
    AdminRevenueOverview rev({int missing = 0, bool fx = false}) =>
        AdminRevenueOverview.fromRow({
          'gross_coaching_cents': 13000,
          'platform_commission_cents': 500,
          'net_platform_cents': 12500,
          'source_currency': 'usd',
          'commission_rate_missing': missing,
          'amount_missing': 0,
          'excluded_non_coaching': 2,
          if (fx) 'fx_usd_gbp_rate': 0.79,
          if (fx) 'fx_as_of': '2026-10-07',
          if (fx) 'fx_source': 'owner-recorded',
        });

    testWidgets('the three figures are shown with their source currency', (t) async {
      await _pump(t, [...allDenied,
        adminRevenueOverviewProvider.overrideWith((_) async => rev())]);
      expect(find.text('USD 130.00'), findsOneWidget);
      expect(find.text('USD 5.00'), findsOneWidget);
      expect(find.text('USD 125.00'), findsOneWidget);
    });

    testWidgets('with no recorded FX the row says so — no pounds figure is '
        'approximated', (t) async {
      await _pump(t, [...allDenied,
        adminRevenueOverviewProvider.overrideWith((_) async => rev())]);
      expect(find.text('FX USD→GBP'), findsOneWidget);
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.textContaining('GBP 1'), findsNothing);
    });

    testWidgets('a recorded rate is shown WITH its date, so the figure is datable',
        (t) async {
      await _pump(t, [...allDenied,
        adminRevenueOverviewProvider.overrideWith((_) async => rev(fx: true))]);
      expect(find.text('FX USD→GBP · 2026-10-07'), findsOneWidget);
      expect(find.text('0.7900'), findsOneWidget);
    });

    testWidgets('an incomplete commission figure DISCLOSES how many payments it '
        'could not account for', (t) async {
      await _pump(t, [...allDenied,
        adminRevenueOverviewProvider.overrideWith((_) async => rev(missing: 3))]);
      expect(find.text('Payments with no recorded rate'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('a complete commission figure does not nag', (t) async {
      await _pump(t, [...allDenied,
        adminRevenueOverviewProvider.overrideWith((_) async => rev())]);
      expect(find.text('Payments with no recorded rate'), findsNothing);
    });
  });

  group('METRIC-11 · two verdicts, never one', () {
    testWidgets('the all-NULL row migration 174 returns means NOT RECORDED for both '
        'halves — the operator is authorized and there is simply nothing yet',
        (t) async {
      await _pump(t, [
        ...allDenied,
        adminReleaseStatusProvider.overrideWith(
            (_) async => AdminReleaseStatus.fromRow(const {})),
      ]);
      expect(find.text('CI status'), findsOneWidget);
      expect(find.text('V5 release gate'), findsOneWidget);
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.text('Not available to your role'), findsWidgets); // other areas
    });

    testWidgets('a recorded disagreement is rendered as a disagreement — CI Passing '
        'beside gate FAIL, separately labelled, with no third combined verdict',
        (t) async {
      await _pump(t, [
        ...allDenied,
        adminReleaseStatusProvider.overrideWith((_) async =>
            AdminReleaseStatus.fromRow(const {
              'release_version': '4.2.0',
              'environment': 'staging',
              'ci_status': 'Passing',
              'ci_checks_passed': 6,
              'ci_checks_total': 6,
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
      expect(find.text('4.2.0 · staging'), findsOneWidget);
      expect(find.text('Passing'), findsOneWidget);
      expect(find.text('FAIL'), findsOneWidget);
      expect(find.text('6 / 6'), findsOneWidget);
      expect(find.text('5 pass · 2 partial · 8 fail of 15'), findsOneWidget);
      // No synthesised overall verdict anywhere.
      final text = _allText(t);
      for (final forbidden in ['BLOCKED', 'Releasable', 'Not releasable', 'Overall']) {
        expect(text.contains(forbidden), isFalse,
            reason: 'the panel must not synthesise "$forbidden" from two '
                'authorities that disagree: $text');
      }
    });
  });
}
