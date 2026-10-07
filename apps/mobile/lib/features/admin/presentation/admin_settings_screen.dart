import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import 'admin_chrome.dart';
import 'admin_metric_tile.dart';
import 'admin_tokens.dart';

/// V5 §186 — P5 · Settings.
///
/// The published section list is the longest of the six pages: `#overview` ·
/// `#organization` · `#users` (Administrators) · `#roles` (Roles & permissions) ·
/// `#platform` (General) · `#notifications` · AI & intelligence · `#privacy` (Data &
/// privacy) · `#security` · `#integrations` (configuration) · `#billing` (Billing &
/// monetization) · `#states`.
///
/// MOST OF IT HAS NO BACKING, AND THE DESIGN IS KEPT ANYWAY. `BOUNDARIES F` is explicit
/// about this posture — *"Designs kept. Approved design requirement;
/// implementation/architecture capability required."* So every section is present and the
/// unbacked ones carry the honest state plus the reason, rather than being dropped
/// (which would make the product smaller to fit the architecture) or filled with invented
/// fields (which would assert a schema nobody designed).
///
/// What is actually backed:
///   * **`#roles`** — `admin_role_capabilities`, the `CONF-D7` artifact itself. Migration
///     155 records *"Owner (Julia) approved the complete 85-cell / 425-grant authorization
///     policy"*, so this section renders **the governing policy**, not a description of it.
///   * **`#users`** — `admin_role_assignments`: who holds an Admin role.
///   * **`#platform`** — `platform_settings`, a generic key/value store whose values are
///     shown as text and interpreted nowhere.
///
/// What is not, and why:
///   * **`#organization`** — **there is no organization table.** Inventing one would mean
///     choosing its fields, which is a product decision.
///   * `#notifications` · AI & intelligence · `#privacy` · `#security` · `#integrations` ·
///     `#billing` — these are configuration surfaces with no configured keys. The store
///     exists; the vocabulary does not, and §77.3's precedent is to refuse to invent one.
///
/// The page is **read-only**. Settings WRITES would each need their own authorization
/// review against the matrix, and none is authorized here.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  /// Sections present in the design with no surface behind them. Named individually so
  /// the page states a specific absence rather than one vague apology.
  static const unbackedSections = <String, String>{
    'Organization': 'No organization record exists in the schema. Its fields are a '
        'product decision, so none is invented here.',
    'Notifications': 'No notification configuration keys are stored.',
    'AI & intelligence': 'No AI configuration keys are stored.',
    'Data & privacy': 'No privacy configuration keys are stored.',
    'Security settings': 'No security configuration keys are stored. Security EVENTS are '
        'on Trust and Operations.',
    'Integration settings': 'No integration configuration keys are stored. Connections '
        'are on Operations and Ecosystem.',
    'Billing & monetization': 'No billing configuration keys are stored. Revenue is on '
        'Ecosystem.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: AdminColors.colorBgCanvas,
        appBar: AppBar(
          backgroundColor: AdminColors.colorBgCanvas,
          surfaceTintColor: AdminColors.colorBgCanvas,
          elevation: 0,
          iconTheme: const IconThemeData(color: AdminColors.colorTextPrimary),
          title: const Text('Settings',
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
            ref.invalidate(adminRoleCapabilitiesProvider);
            ref.invalidate(adminAdministratorCountProvider);
            ref.invalidate(adminPlatformSettingsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AdminDims.space8, AdminDims.space6,
                AdminDims.space8, AdminDims.space20),
            children: [
              _administrators(ref),
              const SizedBox(height: AdminDims.space6),
              _roles(ref),
              const SizedBox(height: AdminDims.space6),
              _platform(ref),
              const SizedBox(height: AdminDims.space6),
              // Every unbacked section, each stating its own absence.
              for (final e in unbackedSections.entries) ...[
                AdminCard(
                  title: e.key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AdminNote('Not recorded'),
                      AdminFootnote(e.value),
                    ],
                  ),
                ),
                const SizedBox(height: AdminDims.space6),
              ],
              const _StatesPanel(),
            ],
          ),
        ),
      );

  Widget _administrators(WidgetRef ref) {
    final async = ref.watch(adminAdministratorCountProvider);
    return AdminCard(
      title: 'Administrators',
      child: async.when(
        loading: () =>
            const AdminPlaceholderRow(label: 'Administrators', text: 'Loading…'),
        error: (_, __) =>
            const AdminPlaceholderRow(label: 'Administrators', text: 'Unavailable'),
        data: (n) => n == null
            ? const AdminMetricTile.absent(
                label: 'Administrators', absence: MetricAbsence.notAuthorized)
            : AdminMetricTile.value(
                label: 'Administrators', value: n, zeroCopy: 'None'),
      ),
    );
  }

  /// `#roles` — the approved matrix itself, summarised per role.
  ///
  /// It renders the POLICY, so it must not round it off. The per-role grant counts and the
  /// total are shown, and the total is the figure `validate-admin-capability-matrix.mjs`
  /// and D14 hold to 116 — a Settings page that disagreed with the validator would be the
  /// first place anyone noticed the matrix had drifted.
  Widget _roles(WidgetRef ref) {
    final async = ref.watch(adminRoleCapabilitiesProvider);
    return AdminCard(
      title: 'Roles & permissions',
      child: async.when(
        loading: () => const AdminNote('Loading…'),
        error: (_, __) => const AdminNote('Unavailable'),
        data: (caps) {
          if (caps == null) return const AdminNote('Not available to your role');
          if (caps.isEmpty) return const AdminNote('None');
          final byRole = <String, int>{};
          final areas = <String>{};
          for (final c in caps) {
            byRole.update(c.adminRole ?? 'unrecognised', (v) => v + 1,
                ifAbsent: () => 1);
            if (c.area != null) areas.add(c.area!);
          }
          final roleNames = byRole.keys.toList()..sort();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminMetricTile.value(label: 'Granted capabilities', value: caps.length),
              AdminMetricTile.value(label: 'Roles', value: byRole.length),
              AdminMetricTile.value(label: 'Areas', value: areas.length),
              const SizedBox(height: AdminDims.space4),
              for (final r in roleNames)
                AdminMetricTile.value(label: r, value: byRole[r]!),
              const AdminFootnote(
                  'This is the approved authorization policy as seeded, not a description '
                  'of it. A figure here disagreeing with the matrix validator would mean '
                  'the policy had drifted.'),
            ],
          );
        },
      ),
    );
  }

  /// `#platform` — the generic key/value store, uninterpreted.
  Widget _platform(WidgetRef ref) {
    final async = ref.watch(adminPlatformSettingsProvider);
    return AdminCard(
      title: 'General',
      child: async.when(
        loading: () => const AdminNote('Loading…'),
        error: (_, __) => const AdminNote('Unavailable'),
        data: (settings) {
          if (settings == null) return const AdminNote('Not available to your role');
          if (settings.isEmpty) return const AdminNote('Not recorded');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in settings)
                AdminMetricTile.text(
                    label: s.key ?? 'setting', display: s.value ?? '—'),
              const AdminFootnote(
                  'Values are shown as stored. This store is generic key/value, so '
                  'nothing here is parsed or unit-converted.'),
            ],
          );
        },
      ),
    );
  }
}

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
            AdminFootnote('Sections with no surface behind them say so individually, '
                'rather than being dropped from the design.'),
            AdminFootnote('This page is read-only. Nothing is changed from this screen.'),
          ],
        ),
      );
}
