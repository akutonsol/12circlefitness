import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import 'admin_chrome.dart';
import 'admin_metric_tile.dart';
import 'admin_tokens.dart';

/// V5 §185 — P5 · People.
///
/// Published sections, in order: `#users` · `#coaches` · `#clients` · `#partners`
/// (Wellness Partners) · `#states`. The page's stated data requirements are *"account list
/// with role, status, last active; coach verification; client assignment; Wellness Partner
/// onboarding and approval states"*.
///
/// THREE OF THOSE ARE NOT BUILT, AND EACH ABSENCE IS STATED RATHER THAN LEFT BLANK:
///
///   * **"last active"** — which signal makes a person active is the open population
///     question (data contract `:98`). METRIC-02 settled which events count for a COUNT,
///     not what makes one individual active. Deriving a per-user recency from
///     `workout_sessions` would answer a question nobody asked.
///   * **"coach verification"** — no verification state exists in the schema. The nearest
///     columns are Stripe onboarding flags, which are a PAYMENTS fact and not a
///     verification one; relabelling them would invent a state machine.
///   * **Partner approval states** — `METRIC-05 = Option 2`: the total only. No approval
///     state machine exists (§77.3) and none was invented, which is the owner's ruling.
///
/// PII IS SHOWN ONLY WHERE THE SECTION IS ABOUT IT. `admin_user_directory` (160) projects
/// nine columns for the Users area and the design asks for an account list, so names and
/// emails appear in `#users`. The aggregate sections show counts and no identifiers, and
/// `avatar_url` is never selected at all.
class AdminPeopleScreen extends ConsumerWidget {
  const AdminPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: AdminColors.colorBgCanvas,
        appBar: AppBar(
          backgroundColor: AdminColors.colorBgCanvas,
          surfaceTintColor: AdminColors.colorBgCanvas,
          elevation: 0,
          iconTheme: const IconThemeData(color: AdminColors.colorTextPrimary),
          title: const Text('People',
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
            ref.invalidate(adminUserOverviewProvider);
            ref.invalidate(adminUserDirectoryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AdminDims.space8, AdminDims.space6,
                AdminDims.space8, AdminDims.space20),
            children: [
              _users(ref),
              const SizedBox(height: AdminDims.space6),
              _coaches(ref),
              const SizedBox(height: AdminDims.space6),
              _clients(ref),
              const SizedBox(height: AdminDims.space6),
              _partners(ref),
              const SizedBox(height: AdminDims.space6),
              const _StatesPanel(),
            ],
          ),
        ),
      );

  Widget _users(WidgetRef ref) {
    final overview = ref.watch(adminUserOverviewProvider);
    final directory = ref.watch(adminUserDirectoryProvider);
    return AdminCard(
      title: 'Users',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          overview.when(
            loading: () => const AdminPlaceholderRow(label: 'Members', text: 'Loading…'),
            error: (_, __) =>
                const AdminPlaceholderRow(label: 'Members', text: 'Unavailable'),
            data: (m) => m == null
                ? const AdminMetricTile.absent(
                    label: 'Members', absence: MetricAbsence.notAuthorized)
                : AdminMetricTile.of('Members', m.usersTotal,
                    whenNull: MetricAbsence.notAuthorized),
          ),
          const SizedBox(height: AdminDims.space4),
          directory.when(
            loading: () => const AdminNote('Loading…'),
            error: (_, __) => const AdminNote('Unavailable'),
            data: (rows) {
              if (rows == null) return const AdminNote('Not available to your role');
              if (rows.isEmpty) return const AdminNote('None');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final u in rows.take(20)) _UserRow(entry: u),
                ],
              );
            },
          ),
          const AdminFootnote(
              '"Last active" is not shown: which signal makes a person active is an open '
              'definition, and deriving one here would answer a question nobody asked.'),
        ],
      ),
    );
  }

  Widget _coaches(WidgetRef ref) => _counts(
        ref,
        'Coaches',
        const ['Coaches', 'Active this month'],
        (m) => [
          AdminMetricTile.of('Coaches', m.coachesTotal,
              whenNull: MetricAbsence.notAuthorized),
          // METRIC-03 = calendar month, and the partition the design requires:
          // "of N · M with no client this month".
          AdminMetricTile.of('Active this month', m.coachesActiveThisMonth,
              whenNull: MetricAbsence.notAuthorized),
          AdminMetricTile.of('No client this month', m.coachesNoClientThisMonth,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          const AdminFootnote(
              'Coach verification is not shown — no verification state exists in the '
              'schema, and the Stripe onboarding flags are a payments fact, not a '
              'verification one.'),
        ],
      );

  Widget _clients(WidgetRef ref) => _counts(
        ref,
        'Clients',
        const ['Clients'],
        (m) => [
          AdminMetricTile.of('Clients', m.clientsTotal,
              whenNull: MetricAbsence.notAuthorized),
          // METRIC-17 = Option 2. The fourth bucket is `unknown`; `age_out_of_range` is a
          // reconciliation figure and is shown only when non-empty, never as a bucket.
          AdminMetricTile.of('Age 18–30', m.age18to30,
              whenNull: MetricAbsence.notAuthorized),
          AdminMetricTile.of('Age 30–45', m.age30to45,
              whenNull: MetricAbsence.notAuthorized),
          AdminMetricTile.of('Age 45–60', m.age45to60,
              whenNull: MetricAbsence.notAuthorized),
          AdminMetricTile.of('Age unknown', m.ageUnknown,
              whenNull: MetricAbsence.notAuthorized),
          if (m.ageOutOfRange != null && m.ageOutOfRange! > 0)
            AdminMetricTile.of('Outside the approved buckets', m.ageOutOfRange,
                whenNull: MetricAbsence.notAuthorized),
        ],
      );

  Widget _partners(WidgetRef ref) => _counts(
        ref,
        'Wellness Partners',
        const ['Partners'],
        (m) => [
          // METRIC-05 = Option 2 — the TOTAL ONLY. No "awaiting approval" sub-count,
          // because no approval state machine exists and the owner ruled it dropped.
          AdminMetricTile.of('Partners', m.vendorsTotal,
              whenNull: MetricAbsence.notAuthorized, zeroCopy: 'None'),
          const AdminFootnote(
              'Total only. Onboarding and approval states are not shown — the schema has '
              'no approval state machine and none was invented.'),
        ],
      );

  static Widget _counts(
    WidgetRef ref,
    String title,
    List<String> labels,
    List<Widget> Function(AdminUserOverview) body,
  ) {
    final async = ref.watch(adminUserOverviewProvider);
    return AdminCard(
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
        data: (m) => m == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final l in labels)
                    AdminMetricTile.absent(
                        label: l, absence: MetricAbsence.notAuthorized)
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, children: body(m)),
      ),
    );
  }
}

/// One account. Shows the name, the role and whether onboarding finished — named as what
/// it is rather than relabelled "status", which would imply a state machine the schema
/// does not have.
class _UserRow extends StatelessWidget {
  const _UserRow({required this.entry});

  final AdminUserDirectoryEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AdminDims.space3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.colorTextPrimary,
                        fontSize: AdminDims.typeSmallSize,
                      )),
                  Text(
                    [
                      if (entry.role != null) entry.role!,
                      if (entry.membershipTier != null) entry.membershipTier!,
                      if (entry.onboardingComplete == false) 'onboarding incomplete',
                    ].join(' · '),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.colorTextSubtle,
                      fontSize: AdminDims.typeCaptionSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// `#states` — the state-system panel the design places on People, naming the states this
/// page actually renders.
class _StatesPanel extends StatelessWidget {
  const _StatesPanel();

  @override
  Widget build(BuildContext context) => const AdminCard(
        title: 'State system',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminFootnote('Loading · Unavailable · Not available to your role · '
                'Not recorded · None'),
            AdminFootnote('"Not available to your role" and "Not recorded" are different '
                'findings and are never shown interchangeably.'),
            AdminFootnote('This page is read-only. Nothing is changed from this screen.'),
          ],
        ),
      );
}
