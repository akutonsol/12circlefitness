import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import '../../../core/observability/app_failure.dart';
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
              _moderationQueue(ref),
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

  /// The moderation queue the design names on `#community`.
  ///
  /// `resolved_at IS NULL` IS the queue, by 170's own comment. The actions are gated on
  /// `Community·update` — held by `content_editor` — and the approved read-only state is
  /// rendered and STATED for anyone else. The inventory requires the shape: *"row actions
  /// open confirm dialogs for destructive changes"*, and hiding or removing a member's
  /// post is destructive.
  Widget _moderationQueue(WidgetRef ref) {
    final async = ref.watch(adminOpenReportsProvider);
    final canModerate = ref.watch(adminCanModerateProvider);
    return AdminCard(
      title: 'Moderation queue',
      child: async.when(
        loading: () => const AdminNote('Loading…'),
        error: (_, __) => const AdminNote('Unavailable'),
        data: (reports) {
          if (reports == null) return const AdminNote('Not available to your role');
          if (reports.isEmpty) return const AdminNote('none open');
          Widget queue(bool writable) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminMetricTile.value(label: 'Open reports', value: reports.length),
              const SizedBox(height: AdminDims.space4),
              for (final r in reports.take(10))
                _ReportRow(report: r, canModerate: writable),
              // The reported CONTENT is not shown here, and that is deliberate: 170's
              // moderation path never writes `content`, and a queue that reproduced the
              // reported text would republish it to every moderator before anyone had
              // judged it.
              const AdminFootnote(
                  'The reported text is not reproduced here. Reasons are as the reporter '
                  'wrote them — there is no reason-code list, which is owner vocabulary.'),
              if (!writable)
                const AdminFootnote(
                    'Read-only: moderating content requires Community · update.'),
            ],
          );
          // A failed capability check is NOT a denial — see [adminCapabilityGate].
          return adminCapabilityGate(
            canModerate,
            allowed: () => queue(true),
            denied: queue(false),
          );
        },
      ),
    );
  }

  Widget _events(WidgetRef ref) => _area<AdminEventsOverview>(
        'Events',
        ref.watch(adminEventsOverviewProvider),
        const ['Events', 'Attendance rate'],
        (m) => [
          // "Create event" is on the approved Ecosystem screen, so the action exists —
          // gated on Events·create, which content_editor holds.
          const _CreateEventAction(),
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


/// One open report. Carries the destructive actions only for a caller holding
/// `Community·update`, and only behind a confirm dialog that names what will change.
class _ReportRow extends ConsumerWidget {
  const _ReportRow({required this.report, required this.canModerate});

  final AdminContentReport report;
  final bool canModerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = report.createdAt?.toIso8601String().split('T').first;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminDims.space3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (report.targetType != null) report.targetType!,
                    if (when != null) when,
                  ].join(' · '),
                  style: const TextStyle(
                    color: AdminColors.colorTextPrimary,
                    fontSize: AdminDims.typeSmallSize,
                  ),
                ),
                // The reporter's own words, shown as written and never mapped to an enum.
                Text(report.reason ?? 'no reason given',
                    style: const TextStyle(
                      color: AdminColors.colorTextSubtle,
                      fontSize: AdminDims.typeCaptionSize,
                    )),
              ],
            ),
          ),
          if (canModerate && report.id != null && report.targetId != null) ...[
            _action(context, ref, 'Hide', 'hidden'),
            _action(context, ref, 'Dismiss', null),
          ],
        ],
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, String label, String? state) =>
      SizedBox(
        height: AdminDims.sizeControl, // 44px, RESPONSIVE.md
        child: TextButton(
          onPressed: () => _confirm(context, ref, label, state),
          style: TextButton.styleFrom(
            foregroundColor: state == null
                ? AdminColors.colorTextMuted
                : AdminColors.colorStatusWarningText,
            minimumSize: const Size(AdminDims.sizeControl, AdminDims.sizeControl),
          ),
          child: Text(label,
              style: const TextStyle(
                fontSize: AdminDims.typeCaptionSize,
                fontWeight: FontWeight.w500,
              )),
        ),
      );

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, String label, String? state) async {
    final destructive = state != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.colorBgSurface,
        title: Text(destructive ? 'Hide this content?' : 'Dismiss this report?',
            style: const TextStyle(
                color: AdminColors.colorTextPrimary,
                fontSize: AdminDims.typeCardTitleSize)),
        content: Text(
          destructive
              // Says exactly what changes and what does not. 170 never writes `content`.
              ? 'The ${report.targetType ?? 'content'} will be hidden from everyone except '
                  'its author and the Community admins. Its text is not altered or '
                  'deleted, and the change is audited.'
              : 'The report is marked resolved. The reported '
                  '${report.targetType ?? 'content'} is left exactly as it is.',
          style: const TextStyle(
              color: AdminColors.colorTextSecondary,
              fontSize: AdminDims.typeSmallSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AdminColors.colorTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(destructive ? 'Hide' : 'Dismiss',
                style: const TextStyle(
                    color: AdminColors.colorBrandAccent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final svc = ref.read(adminMetricsServiceProvider);
    try {
      if (destructive) {
        await svc.moderate(report.targetType!, report.targetId!, state);
      }
      await svc.resolveReport(report.id!);
      ref.invalidate(adminOpenReportsProvider);
      ref.invalidate(adminCommunityOverviewProvider);
    } catch (e, st) {
      // Reported, not shown raw (ERR-G2), and never silent — a moderation action that
      // was refused must not read as one that succeeded.
      reportError('admin_ecosystem.moderate', e, st, {
        'report_id': report.id,
        'target_type': report.targetType,
        'state': state,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AdminColors.colorBgRaised,
          content: Text(
              'That action was not applied. You may not have permission, or the report '
              'has changed. Nothing was altered.',
              style: TextStyle(color: AdminColors.colorStatusDangerText)),
        ));
      }
    }
  }
}


/// The approved screen's "Create event" action.
///
/// DESCRIPTIVE FIELDS ONLY, and that is the governed path's rule rather than this form's
/// simplicity: `admin_create_event` (165) accepts title, date, description, location,
/// end date, cover image, host and capacity — and deliberately NOT `price`, `is_free`,
/// `status`, `current_registered` or `vendor_id`. An Admin may describe an event; pricing,
/// publishing and vendor assignment are not Admin acts. The form offers no field for them
/// because the function has no parameter for them, and a form that collected them would
/// imply an authority that does not exist.
class _CreateEventAction extends ConsumerWidget {
  const _CreateEventAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return adminCapabilityGate(
      ref.watch(adminCanCreateEventsProvider),
      denied: const AdminFootnote(
          'Read-only: creating an event requires Events · create.'),
      allowed: () => _button(context, ref),
    );
  }

  Widget _button(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: AdminDims.sizeControl, // 44px, RESPONSIVE.md
        child: TextButton(
          onPressed: () => _open(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: AdminColors.colorBrandAccent,
            minimumSize: const Size(AdminDims.sizeControl, AdminDims.sizeControl),
          ),
          child: const Text('Create event',
              style: TextStyle(
                fontSize: AdminDims.typeCaptionSize,
                fontWeight: FontWeight.w500,
              )),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final location = TextEditingController();
    final capacity = TextEditingController();
    DateTime? when;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AdminColors.colorBgSurface,
          title: const Text('Create event',
              style: TextStyle(
                  color: AdminColors.colorTextPrimary,
                  fontSize: AdminDims.typeCardTitleSize)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: title,
                style: const TextStyle(
                    color: AdminColors.colorTextPrimary,
                    fontSize: AdminDims.typeSmallSize),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: AdminColors.colorTextMuted),
                ),
              ),
              TextField(
                controller: location,
                style: const TextStyle(
                    color: AdminColors.colorTextPrimary,
                    fontSize: AdminDims.typeSmallSize),
                decoration: const InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: AdminColors.colorTextMuted),
                ),
              ),
              TextField(
                controller: capacity,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: AdminColors.colorTextPrimary,
                    fontSize: AdminDims.typeSmallSize),
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  labelStyle: TextStyle(color: AdminColors.colorTextMuted),
                ),
              ),
              const SizedBox(height: AdminDims.space6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        when == null
                            ? 'No date chosen'
                            : when!.toIso8601String().split('T').first,
                        style: const TextStyle(
                            color: AdminColors.colorTextSecondary,
                            fontSize: AdminDims.typeSmallSize)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 3),
                      );
                      // `ctx.mounted` first. LIFE-G1 caught this calling setState after
                      // an await with no check — the dialog can be dismissed while the
                      // date picker is open, and setState on a disposed element throws.
                      if (picked != null && ctx.mounted) {
                        setState(() => when = picked);
                      }
                    },
                    child: const Text('Choose date',
                        style: TextStyle(color: AdminColors.colorBrandAccent)),
                  ),
                ],
              ),
              const SizedBox(height: AdminDims.space4),
              // Says what an Admin may NOT set, so its absence is not read as a
              // missing field.
              const Text(
                  'Price, free/paid, publication status and vendor are not set here — '
                  'the governed path accepts none of them.',
                  style: TextStyle(
                      color: AdminColors.colorTextSubtle,
                      fontSize: AdminDims.typeCaptionSize)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: AdminColors.colorTextMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Create',
                  style: TextStyle(
                      color: AdminColors.colorBrandAccent,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final t = title.text.trim();
    // The governed path requires a title and a date; the form does not pretend otherwise.
    if (t.isEmpty || when == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AdminColors.colorBgRaised,
          content: Text('An event needs a title and a date. Nothing was created.',
              style: TextStyle(color: AdminColors.colorStatusWarningText)),
        ));
      }
      return;
    }
    try {
      await ref.read(adminMetricsServiceProvider).createEvent(
            title: t,
            eventDate: when!,
            location: location.text.trim().isEmpty ? null : location.text.trim(),
            maxCapacity: int.tryParse(capacity.text.trim()),
          );
      ref.invalidate(adminEventsOverviewProvider);
    } catch (e, st) {
      reportError('admin_ecosystem.createEvent', e, st, {'title': t});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AdminColors.colorBgRaised,
          content: Text(
              'The event was not created. You may not have permission. Nothing was '
              'saved.',
              style: TextStyle(color: AdminColors.colorStatusDangerText)),
        ));
      }
    }
  }
}
