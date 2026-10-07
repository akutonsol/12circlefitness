import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import 'admin_chrome.dart';
import 'admin_metric_tile.dart';
import 'admin_tokens.dart';

/// V5 §184 — P5 · Ecosystem.
///
/// Sections are the published ones, in the published order (`SCREEN-INVENTORY.md` at
/// `931218b`): `#overview` · `#community` · `#events` · `#training` · `#monetization` ·
/// `#wearables`. The page's stated data requirements are *"community posts, reports and
/// moderation queue; events and attendance; training content and completion;
/// monetisation (plans, payouts, commission); wearable connections"* — every one reads a
/// surface migrations 156/157/166/170/171/172/178 already publish. **No schema was added
/// for this screen.**
///
/// TWO THINGS IT DELIBERATELY DOES NOT SHOW.
///
/// 1. **Wearable sync health.** The data contract splits that tile — *"its connection
///    half is buildable now … its ingestion-health half depends on `WI-13` and waits for
///    `PD-G01`"* — and `PD-G01` is `APPROVED — FUTURE BUILD · implementation NOT
///    AUTHORIZED`. So connections are counted and no latency, sync status or error rate
///    is invented. The card says so rather than leaving a silent hole.
/// 2. **A training "completion rate".** The design asks for *"training content and
///    completion"*; `admin_training_overview` publishes raw counts and no ruled
///    denominator exists for a rate. Counts are shown; a rate is not derived.
class AdminEcosystemScreen extends ConsumerWidget {
  const AdminEcosystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: AdminColors.colorBgCanvas,
        appBar: AppBar(
          backgroundColor: AdminColors.colorBgCanvas,
          surfaceTintColor: AdminColors.colorBgCanvas,
          elevation: 0,
          iconTheme: const IconThemeData(color: AdminColors.colorTextPrimary),
          title: const Text('Ecosystem',
              style: TextStyle(
                color: AdminColors.colorTextPrimary,
                fontSize: AdminDims.typeSectionTitleSize,
                fontWeight: FontWeight.w500,
              )),
        ),
        body: RefreshIndicator(
          color: AdminColors.colorBrandAccent,
          backgroundColor: AdminColors.colorBgSurface,
          onRefresh: () async {
            ref.invalidate(adminCommunityOverviewProvider);
            ref.invalidate(adminEventsOverviewProvider);
            ref.invalidate(adminTrainingOverviewProvider);
            ref.invalidate(adminRevenueOverviewProvider);
            ref.invalidate(adminWearableConnectionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AdminDims.space8, AdminDims.space6,
                AdminDims.space8, AdminDims.space20),
            children: [
              _overview(ref),
              const SizedBox(height: AdminDims.space6),
              _community(ref),
              const SizedBox(height: AdminDims.space6),
              _events(ref),
              const SizedBox(height: AdminDims.space6),
              _training(ref),
              const SizedBox(height: AdminDims.space6),
              _monetization(ref),
              const SizedBox(height: AdminDims.space6),
              _wearables(ref),
            ],
          ),
        ),
      );

  /// Renders one area, keeping the four states apart: loading · error · no capability ·
  /// the data. A null model means the surface returned no row, which is an authorization
  /// outcome for the whole area — so the card states that rather than vanishing.
  static Widget _area<T>(
    String title,
    AsyncValue<T?> async,
    List<String> labels,
    List<Widget> Function(T) body,
  ) =>
      AdminCard(
        title: title,
        child: async.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final l in labels) AdminPlaceholderRow(label: l, text: 'Loading…')
            ],
          ),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final l in labels) AdminPlaceholderRow(label: l, text: 'Unavailable')
            ],
          ),
          data: (v) => v == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final l in labels)
                      AdminMetricTile.absent(
                          label: l, absence: MetricAbsence.notAuthorized)
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: body(v)),
        ),
      );

  Widget _overview(WidgetRef ref) => _area<AdminCommunityOverview>(
        'Overview',
        ref.watch(adminCommunityOverviewProvider),
        const ['Pods', 'Posts'],
        (m) => [
          AdminMetricTile.of('Pods', m.podsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Posts', m.postsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
        ],
      );

  Widget _community(WidgetRef ref) => _area<AdminCommunityOverview>(
        'Community',
        ref.watch(adminCommunityOverviewProvider),
        const ['Pods', 'Groups', 'Reports open'],
        (m) => [
          AdminMetricTile.of('Pods', m.podsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Pods active', m.podsActive,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          // Reported beside pods, never merged into them — different units.
          AdminMetricTile.of('Groups', m.communityGroupsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Posts', m.postsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Posts visible', m.postsVisible,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          // The moderation queue the design names: unresolved reports.
          AdminMetricTile.of('Reports open', m.reportsOpen,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'none open'),
        ],
      );

  Widget _events(WidgetRef ref) => _area<AdminEventsOverview>(
        'Events',
        ref.watch(adminEventsOverviewProvider),
        const ['Events', 'Attendance rate'],
        (m) => [
          AdminMetricTile.of('Events', m.eventsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Registrations · 30 d', m.registrations30d,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Attended', m.registrationsAttended,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          // NULL with nothing to divide — an A11 state, never "0%".
          if (m.attendanceRatePct != null)
            AdminMetricTile.text(
                label: 'Attendance rate',
                display: '${m.attendanceRatePct!.toStringAsFixed(1)}%')
          else
            const AdminMetricTile.absent(
                label: 'Attendance rate', absence: MetricAbsence.notRecorded),
        ],
      );

  Widget _training(WidgetRef ref) => _area<AdminTrainingOverview>(
        'Training',
        ref.watch(adminTrainingOverviewProvider),
        const ['Programs', 'Sessions'],
        (m) => [
          AdminMetricTile.of('Programs', m.programsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Workouts', m.workoutsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Sessions', m.sessionsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          AdminMetricTile.of('Logs', m.logsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          const AdminFootnote(
              'Counts only. No completion rate is derived — the design asks for '
              '"completion" and no ruled denominator exists for one.'),
        ],
      );

  Widget _monetization(WidgetRef ref) => _area<AdminRevenueOverview>(
        'Monetization',
        ref.watch(adminRevenueOverviewProvider),
        const ['Gross coaching', 'Paid to coaches'],
        (m) {
          final cur = (m.sourceCurrency ?? '').toUpperCase();
          String? money(int? c) =>
              c == null ? null : '$cur ${(c / 100).toStringAsFixed(2)}';
          Widget tile(String label, String? d) => d == null
              ? AdminMetricTile.absent(
                  label: label, absence: MetricAbsence.notAuthorized)
              : AdminMetricTile.text(label: label, display: d);
          return [
            tile('Gross coaching', money(m.grossCoachingCents)),
            tile('Platform commission', money(m.platformCommissionCents)),
            // The split as recorded — never derived from amount x rate.
            tile('Paid to coaches', money(m.coachPayoutCents)),
            tile('Platform fee', money(m.platformFeeCents)),
            if (m.payoutMissing != null && m.payoutMissing! > 0)
              AdminMetricTile.of('Payments with no recorded split', m.payoutMissing,
                  whenNull: MetricAbsence.notAuthorized),
            if (!m.commissionIsComplete)
              AdminMetricTile.of(
                  'Payments with no recorded rate', m.commissionRateMissing,
                  whenNull: MetricAbsence.notAuthorized),
          ];
        },
      );

  Widget _wearables(WidgetRef ref) => _area<AdminWearableConnections>(
        'Wearables',
        ref.watch(adminWearableConnectionsProvider),
        const ['Connections'],
        (m) => [
          AdminMetricTile.value(
              label: 'Connections', value: m.connectedTotal, zeroCopy: 'None'),
          for (final e in m.byProvider.entries)
            AdminMetricTile.value(label: e.key, value: e.value),
          // PD-G01 is APPROVED — FUTURE BUILD, implementation NOT AUTHORIZED. The
          // absence of sync health is a ruling, so the card states it rather than
          // leaving a hole a reader would assume was an oversight.
          const AdminFootnote(
              'Connections only. Sync health, latency and ingestion errors are WI-13 '
              'and wait on PD-G01 — nothing here estimates them.'),
        ],
      );
}
