import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import 'admin_attention_queue.dart';
import 'admin_chrome.dart';
import 'admin_metric_tile.dart';
import 'admin_tokens.dart';

/// V5 §166 — the owner-approved metrics, rendered.
///
/// One `Card` per area, following `COMPONENT-SPECS.md` › Card
/// (`--adm-color-bg-surface`, `--adm-radius-xl`, the `--adm-shadow-edge` inset ring)
/// and › Stat tile for the rows. Every colour and dimension comes from
/// [AdminColors] / [AdminDims], which are generated from the published
/// `admin.tokens.css` at commit `931218b`.
///
/// HOW EACH ABSENCE IS CLASSIFIED, AND WHY IT IS NOT A GUESS.
///   * The provider yields **null** → the view returned no row → the caller holds no
///     capability for that area → [MetricAbsence.notAuthorized].
///   * A **null column** inside a present model → the caller is authorized for the
///     area but not for that figure. This is METRIC-02's case, where the sign-in
///     basis is gated on `Security·view` per ruling `B-1` → also `notAuthorized`.
///   * METRIC-11's **all-NULL row** → authorized, nothing recorded →
///     [MetricAbsence.notRecorded]. Migration 174 exists so this case is
///     distinguishable at all.
///
/// Loading and error are rendered as their own `A11` states rather than as zeros,
/// because a card that shows `0` while still loading has told the operator something
/// false about the platform.
class AdminMetricsPanel extends ConsumerWidget {
  const AdminMetricsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The approved Control Center places the attention queue FIRST — the page is
        // called "Needs your attention" before it is anything else.
        const AdminAttentionQueue(),
        const SizedBox(height: AdminDims.space6),
        _activity(ref),
        const SizedBox(height: AdminDims.space6),
        _people(ref),
        const SizedBox(height: AdminDims.space6),
        _community(ref),
        const SizedBox(height: AdminDims.space6),
        _events(ref),
        const SizedBox(height: AdminDims.space6),
        _revenue(ref),
        const SizedBox(height: AdminDims.space6),
        _release(ref),
        const SizedBox(height: AdminDims.space6),
        const _DashboardAbsences(),
      ],
    );
  }

  // ── METRIC-02 ─────────────────────────────────────────────────────────────
  /// The window footnote. It is NOT decoration: the data contract names the timezone
  /// as an unsettled sub-question, so a reader has to be able to see what "today"
  /// meant. Rendered only when the surface actually reported it.
  /// Returns a LIST so it can be spread. A null-aware element (`?expr`) needs Dart
  /// 3.8, which this package's SDK constraint predates.
  static List<Widget> _windowNote(AdminActivityOverview m) {
    if (m.dayStart == null || m.windowTimezone == null) return const [];
    final d = m.dayStart!.toIso8601String().split('T').first;
    return [
      Padding(
        padding: const EdgeInsets.only(top: AdminDims.space4),
        child: Text('Day begins $d 00:00 ${m.windowTimezone}',
            style: const TextStyle(
              color: AdminColors.colorTextSubtle,
              fontSize: AdminDims.typeCaptionSize,
            )),
      ),
    ];
  }

  Widget _activity(WidgetRef ref) => AdminCard(
        title: 'Activity',
        child: _async<AdminActivityOverview>(
          ref.watch(adminActivityOverviewProvider),
          labels: const ['Active today · Sessions', 'Daily sessions',
                         'Active today · Sign-ins'],
          builder: (m) => [
            // The two bases are shown SEPARATELY, as the owner ruled. They are not
            // added together and no single "active users" figure is derived from
            // them, because they measure different things over different populations.
            AdminMetricTile.of('Active today · Sessions', m.sessionUsersToday,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('This week · Sessions', m.sessionUsersWeek,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('This month · Sessions', m.sessionUsersMonth,
                whenNull: MetricAbsence.notAuthorized,
                delta: m.sessionMonthDelta),
            // SESSION COUNTS, labelled as such. The design shows "947 Daily sessions"
            // beside the DAU figure and the data contract calls them distinct required
            // measures, so they are never substituted for one another here.
            AdminMetricTile.of('Daily sessions', m.sessionsToday,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Sessions this month', m.sessionsMonth,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Active today · Sign-ins', m.signInUsersToday,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('This week · Sign-ins', m.signInUsersWeek,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('This month · Sign-ins', m.signInUsersMonth,
                whenNull: MetricAbsence.notAuthorized,
                delta: m.signInMonthDelta),
            ..._windowNote(m),
          ],
        ),
      );

  // ── METRIC-03 · METRIC-05 · METRIC-17 ─────────────────────────────────────
  Widget _people(WidgetRef ref) => AdminCard(
        title: 'People',
        child: _async<AdminUserOverview>(
          ref.watch(adminUserOverviewProvider),
          labels: const ['Members', 'Coaches'],
          builder: (m) => [
            AdminMetricTile.of('Members', m.usersTotal,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('Coaches', m.coachesTotal,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('Active this month', m.coachesActiveThisMonth,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('No client this month', m.coachesNoClientThisMonth,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            // METRIC-05 = Option 2: the total only. No "awaiting approval"
            // sub-count, because no approval state machine exists.
            AdminMetricTile.of('Wellness partners', m.vendorsTotal,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Age 18–30', m.age18to30,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('Age 30–45', m.age30to45,
                whenNull: MetricAbsence.notAuthorized),
            AdminMetricTile.of('Age 45–60', m.age45to60,
                whenNull: MetricAbsence.notAuthorized),
            // METRIC-17 = Option 2: the fourth bucket.
            AdminMetricTile.of('Age unknown', m.ageUnknown,
                whenNull: MetricAbsence.notAuthorized),
            // NOT a fifth bucket. Shown only when non-zero, and labelled as what it
            // is — records the approved buckets cannot represent. The owner ruled no
            // 60+ bucket may be invented, and hiding these would instead make the
            // panel misstate its own total.
            // A visibility test, not a rendered value: shown only when there is
            // genuinely someone outside the buckets. Written explicitly rather than
            // as `?? 0` so it is not mistaken for coercing an absent figure to zero
            // — and so SEC-G4's scan of this directory stays meaningful.
            if (m.ageOutOfRange != null && m.ageOutOfRange! > 0)
              AdminMetricTile.of('Outside the approved buckets', m.ageOutOfRange,
                  whenNull: MetricAbsence.notAuthorized),
          ],
        ),
      );

  // ── METRIC-13 ─────────────────────────────────────────────────────────────
  Widget _community(WidgetRef ref) => AdminCard(
        title: 'Community',
        child: _async<AdminCommunityOverview>(
          ref.watch(adminCommunityOverviewProvider),
          labels: const ['Pods', 'Groups'],
          builder: (m) => [
            AdminMetricTile.of('Pods', m.podsTotal,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Pods active', m.podsActive,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            // Reported beside pods, never merged into them.
            AdminMetricTile.of('Groups', m.communityGroupsTotal,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Posts', m.postsTotal,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Reports open', m.reportsOpen,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'none open'),
          ],
        ),
      );

  // ── METRIC-14 ─────────────────────────────────────────────────────────────
  Widget _events(WidgetRef ref) => AdminCard(
        title: 'Events',
        child: _async<AdminEventsOverview>(
          ref.watch(adminEventsOverviewProvider),
          labels: const ['Events', 'Attendance rate'],
          builder: (m) => [
            AdminMetricTile.of('Events', m.eventsTotal,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Registrations · 30 d', m.registrations30d,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            AdminMetricTile.of('Attended', m.registrationsAttended,
                whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
            // NULL rate with nothing to divide, so this renders an absence rather
            // than "0%" — "nobody registered" is not "nobody turned up".
            if (m.attendanceRatePct != null)
              AdminMetricTile.text(
                  label: 'Attendance rate',
                  display: '${m.attendanceRatePct!.toStringAsFixed(1)}%')
            else
              const AdminMetricTile.absent(
                  label: 'Attendance rate', absence: MetricAbsence.notRecorded),
          ],
        ),
      );

  // ── METRIC-06a · METRIC-06b ───────────────────────────────────────────────
  Widget _revenue(WidgetRef ref) => AdminCard(
        title: 'Revenue',
        child: _async<AdminRevenueOverview>(
          ref.watch(adminRevenueOverviewProvider),
          labels: const ['Gross coaching', 'Platform commission'],
          builder: (m) {
            final cur = (m.sourceCurrency ?? '').toUpperCase();
            String? money(int? cents) =>
                cents == null ? null : '$cur ${(cents / 100).toStringAsFixed(2)}';
            return [
              _moneyTile('Gross coaching', money(m.grossCoachingCents)),
              _moneyTile('Platform commission', money(m.platformCommissionCents)),
              _moneyTile('Net to platform', money(m.netPlatformCents)),
              // THE INCOMPLETENESS IS SHOWN, NOT HIDDEN. Payments with no recorded
              // rate are in gross and not in commission, so the commission figure is
              // a floor. An operator reading it as a total would be wrong, and the
              // owner's calculation forbids inventing the missing rates.
              if (!m.commissionIsComplete)
                AdminMetricTile.of(
                    'Payments with no recorded rate', m.commissionRateMissing,
                    whenNull: MetricAbsence.notAuthorized),
              // REVENUE BY STREAM (approved design, Dashboard). The vocabulary is
              // iterated, not hard-coded, so a seventh stream appears the day the
              // surface reports one.
              for (final e in m.streams.entries)
                _moneyTile('Stream · ${_streamLabel(e.key)}', money(e.value)),
              // Shown only when non-zero, and labelled as what it is. `payments.kind`
              // has no CHECK constraint, so this is reachable — and hiding it would
              // understate revenue, the one direction a money figure must not be wrong.
              // Explicit, not `?? 0` — a visibility test must not read as coercing an
              // absent figure to zero, and SEC-G4 caught me reintroducing exactly that.
              if (m.streamOtherCents != null && m.streamOtherCents! > 0)
                _moneyTile('Stream · unrecognised', money(m.streamOtherCents)),
              // THE SPLIT, as recorded. Never derived.
              _moneyTile('Paid to coaches', money(m.coachPayoutCents)),
              _moneyTile('Platform fee', money(m.platformFeeCents)),
              if (m.payoutMissing != null && m.payoutMissing! > 0)
                AdminMetricTile.of('Payments with no recorded split', m.payoutMissing,
                    whenNull: MetricAbsence.notAuthorized),
              // METRIC-06a. No GBP figure exists without a recorded rate, and none
              // is approximated.
              if (m.hasRecordedFx)
                AdminMetricTile.text(
                    label: 'FX USD→GBP · ${m.fxAsOf!.toIso8601String().split('T').first}',
                    display: m.fxUsdGbpRate!.toStringAsFixed(4))
              else
                const AdminMetricTile.absent(
                    label: 'FX USD→GBP', absence: MetricAbsence.notRecorded),
            ];
          },
        ),
      );

  /// The design names these as streams; the database names them in the
  /// `create-checkout:52` vocabulary. This maps one to the other and invents no new
  /// stream — an unrecognised key is shown as itself rather than guessed at.
  static String _streamLabel(String kind) => const {
        'coach': 'coaching',
        'coach_plan': 'coach plans',
        'self_guided': 'self-guided',
        'ai_guided': 'AI-guided',
        'event_ticket': 'event tickets',
        'package': 'session packages',
      }[kind] ??
      kind;

  static Widget _moneyTile(String label, String? display) => display == null
      ? AdminMetricTile.absent(
          label: label, absence: MetricAbsence.notAuthorized)
      : AdminMetricTile.text(label: label, display: display);

  // ── METRIC-11 ─────────────────────────────────────────────────────────────
  Widget _release(WidgetRef ref) => AdminCard(
        title: 'QA & release',
        child: _async<AdminReleaseStatus>(
          ref.watch(adminReleaseStatusProvider),
          labels: const ['CI status', 'V5 release gate'],
          builder: (m) {
            // 174's contract: a visible row means the caller HOLDS `System·view`, so
            // nothing inside it can be an authorization absence. Both remaining
            // cases are therefore `notRecorded` — the all-NULL row (nothing recorded
            // at all) and a row where one verdict was recorded and the other was
            // not, which the table's provenance CHECK makes all-or-nothing per half.
            // An earlier draft wrote this as a ternary whose two branches were
            // identical; it is a constant because the two cases genuinely coincide.
            const absence = MetricAbsence.notRecorded;
            return [
              if (m.releaseVersion != null)
                AdminMetricTile.text(
                    label: 'Release',
                    display: '${m.releaseVersion}'
                        '${m.environment != null ? ' · ${m.environment}' : ''}'),
              // THE TWO VERDICTS ARE RENDERED SEPARATELY AND LABELLED SEPARATELY.
              // Nothing here combines them, and nothing derives a third verdict from
              // them — they disagree today, and that is the finding.
              if (m.hasCiVerdict)
                AdminMetricTile.text(label: 'CI status', display: m.ciStatus!)
              else
                AdminMetricTile.absent(label: 'CI status', absence: absence),
              // BOTH halves of the fraction, or neither. An earlier draft wrote
              // `ciChecksPassed ?? 0`, which would render "0 / 6" when the passed
              // count was simply not recorded — asserting that every check failed.
              if (m.ciChecksPassed != null && m.ciChecksTotal != null)
                AdminMetricTile.text(
                    label: 'CI checks',
                    display: '${m.ciChecksPassed} / ${m.ciChecksTotal}'),
              if (m.hasGateVerdict)
                AdminMetricTile.text(
                    label: 'V5 release gate', display: m.gateVerdict!)
              else
                AdminMetricTile.absent(label: 'V5 release gate', absence: absence),
              // All four figures or none, for the same reason: "0 pass · 0 partial ·
              // 0 fail of 15" is a statement about the ledger that nobody made. The
              // table's reconciliation CHECK already guarantees they travel together
              // when present, so requiring all four costs nothing.
              if (m.gatesPass != null &&
                  m.gatesPartial != null &&
                  m.gatesFail != null &&
                  m.gatesTotal != null)
                AdminMetricTile.text(
                    label: 'Gates',
                    display: '${m.gatesPass} pass · ${m.gatesPartial} '
                        'partial · ${m.gatesFail} fail of ${m.gatesTotal}'),
            ];
          },
        ),
      );

  /// Maps an [AsyncValue] onto the `A11` states. A null value means the surface
  /// returned no row, which is an authorization outcome for the whole area — so
  /// every label is rendered as `notAuthorized` rather than the card vanishing,
  /// because a card that disappears tells the operator nothing about why.
  static Widget _async<T>(
    AsyncValue<T?> async, {
    required List<String> labels,
    required List<Widget> Function(T) builder,
  }) =>
      async.when(
        loading: () => _states(labels, _A11.loading),
        error: (_, __) => _states(labels, _A11.error),
        data: (v) => v == null
            ? _states(labels, _A11.denied)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: builder(v)),
      );

  static Widget _states(List<String> labels, _A11 state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final l in labels)
            if (state == _A11.denied)
              AdminMetricTile.absent(
                  label: l, absence: MetricAbsence.notAuthorized)
            else
              AdminPlaceholderRow(label: l, text: state.copy),
        ],
      );
}

enum _A11 {
  loading('Loading…'),
  error('Unavailable'),
  denied('');

  const _A11(this.copy);
  final String copy;
}

/// The Control Center requirements that are NOT shown, each with its own reason.
///
/// WHY THIS CARD EXISTS. Every other Admin page states its absences — People 7, Trust 10,
/// Ecosystem 6, Settings 6, Operations 3 — and this page stated **none**, while carrying
/// the MOST unbuildable requirements of the six. §185.2's own rule is that *"a blank where a
/// requirement was is indistinguishable from an oversight; a sentence saying why is not"*,
/// and the page that most needed it was the one without it.
///
/// NOTHING HERE IS A NEW JUDGEMENT. Each line restates a ruling already on the record, and
/// the reasons are deliberately DISTINCT — a shared placeholder would masquerade as seven
/// findings, which is the defect §186's test was written to catch on Settings.
/// The absence map, named so a guard can assert its SHAPE without reaching into a private
/// widget. It carries no behaviour — only the published requirement and its recorded reason.
abstract final class AdminMetricsPanelAbsences {
  static const all = _DashboardAbsences.absences;
}

class _DashboardAbsences extends StatelessWidget {
  const _DashboardAbsences();

  /// Keyed by the published requirement, valued by the reason it is not shown.
  static const absences = <String, String>{
    'Churn': 'No churn definition is ruled. It appears in the monetisation roadmap beside '
        'MRR and ARPU and was never put as a metric decision, so there is nothing to '
        'compute — and inventing one would be inventing monetisation.',
    'Service health feed': 'No surface produces service health. The approved design\'s own '
        '"Requires architectural verification" panel records the same gap.',
    'AI Guardian findings': 'The Guardian STATE is on Trust. Its findings need the action '
        'queue, which has no store and no defined action shape — P7.',
    'Wearable sync status': 'Connections are counted on Ecosystem. Ingestion health depends '
        'on WI-13 and waits for PD-G01, whose implementation is not authorized.',
    'Installs': 'Ruled: reading our own store consoles is the vendor boundary PD-A24 '
        'forecloses, so this renders empty by decision — not for want of work.',
    'Impressions': 'Semantically defined as eligible content renders, and no producer '
        'exists to emit one.',
    'Audit-log tail': 'The approved screen DOES place a "Recent admin activity" section '
        'here. It is not built because two of its four designed row types have no producer '
        '(a Guardian finding needs P7) or no category (a release is not an audit event '
        'under the ruled vocabulary), and all four name the actor, which no audit surface '
        'in this layer resolves. The full projection is on Trust. Owner question Q12.',
  };

  @override
  Widget build(BuildContext context) => AdminCard(
        title: 'Not shown here',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in absences.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AdminDims.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key,
                        style: const TextStyle(
                            color: AdminColors.colorTextSecondary,
                            fontSize: AdminDims.typeSmallSize,
                            fontWeight: FontWeight.w500)),
                    AdminFootnote(e.value),
                  ],
                ),
              ),
          ],
        ),
      );
}
