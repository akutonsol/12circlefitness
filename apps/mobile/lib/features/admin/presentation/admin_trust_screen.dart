import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/observability/app_failure.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import '../domain/admin_trust.dart';
import 'admin_metric_tile.dart';
import 'admin_chrome.dart';
import 'admin_tokens.dart';

/// V5 §183 — P6 · Trust.
///
/// The sections are the published ones, in the published order
/// (`SCREEN-INVENTORY.md` at `931218b`): `#overview` · `#ai-guardian` ·
/// `#security` (incl. `#sec-authz`) · `#incidents` · `#audit` · `#trust-system`. The
/// design's stated data requirements for this page are *"AI Guardian actions and
/// autonomy; auth and authorisation events; incidents; immutable audit log with
/// before/after"*, and every one is read from a surface migrations 156/159/160/163/169
/// already publish — nothing new was added to the schema for this screen.
///
/// A CORRECTION TO §183. This page was first shipped as read-only on the stated grounds
/// that it was *"a design rule"*, citing `CONF-D5`'s drawer footer — *"Actions open the
/// item. Nothing is changed from this screen."* **That was wrong about the page.** That
/// footer governs the attention-queue DRAWER, and the approved Trust screen itself
/// contains action controls: `Resolve` appears three times, alongside `Investigate` and
/// *"Assign, change status, add…"*. `Read-only` is listed in the inventory as one of the
/// **states** designed for Trust, Operations and Settings — a state for a role that may
/// view and not update, not a property of the surface.
///
/// So incident resolution is implemented, and the read-only state is rendered for anyone
/// without `Incidents·update` — a capability `trust_lead` holds alone. The inventory's
/// Interactions section requires the shape: *"row actions open confirm dialogs for
/// destructive changes."*
///
/// THE GUARDIAN REMAINS READ-ONLY HERE, and that one IS a rule: `A10` bars the Guardian
/// from holding admin authority, re-stating it goes through `admin_set_guardian_state`
/// gated `AI Guardian·manage`, and nothing on this page calls it.
///
/// WHAT IT REFUSES TO DO, each a defect this programme has already paid for once:
///   * it never resolves `subject_pseudonym` — §19.3, and the model gives it no way to;
///   * it never presents an unrecorded Guardian state as `Active` — that is EC-04's
///     coercion applied to a safety control;
///   * it states `A13·1` on the audit section rather than implying a complete ledger;
///   * loading, error, "no capability" and "nothing recorded" are four distinct states;
///   * it never presents a write as having happened when the governed path refused it.
class AdminTrustScreen extends ConsumerWidget {
  const AdminTrustScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AdminColors.colorBgCanvas,
      appBar: AppBar(
        backgroundColor: AdminColors.colorBgCanvas,
        surfaceTintColor: AdminColors.colorBgCanvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: AdminColors.colorTextPrimary),
        title: const Text('Trust',
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
          ref.invalidate(adminGuardianStateProvider);
          ref.invalidate(adminCanViewGuardianProvider);
          ref.invalidate(adminGovernancePoliciesProvider);
          ref.invalidate(adminSecurityEventsProvider);
          ref.invalidate(adminIncidentsProvider);
          ref.invalidate(adminAuditEventsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AdminDims.space8, AdminDims.space6,
              AdminDims.space8, AdminDims.space20),
          children: [
            _overview(ref),
            const SizedBox(height: AdminDims.space6),
            _aiGuardian(ref),
            const SizedBox(height: AdminDims.space6),
            _security(ref),
            const SizedBox(height: AdminDims.space6),
            _incidents(ref),
            const SizedBox(height: AdminDims.space6),
            _audit(ref),
            const SizedBox(height: AdminDims.space6),
            const _TrustSystemPanel(),
          ],
        ),
      ),
    );
  }

  // ── #overview ───────────────────────────────────────────────────────────
  Widget _overview(WidgetRef ref) {
    final guardian = ref.watch(adminGuardianStateProvider);
    final canGuardian = ref.watch(adminCanViewGuardianProvider);
    final incidents = ref.watch(adminIncidentsProvider);
    final security = ref.watch(adminSecurityEventsProvider);
    return AdminCard(
      title: 'Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The Guardian reading is NOT a boolean. `guardianIsHealthy` returns null for
          // "cannot say", and this renders that rather than resolving it to a reassuring
          // answer. The capability is read from its own provider so that "you may not
          // see this" and "nothing is recorded" stay distinguishable.
          _guardianHealthTile(guardian, canGuardian),
          _countTile('Open incidents', incidents,
              (l) => l.where((i) => i.resolution == null).length,
              zeroCopy: 'none open'),
          _countTile('Security events', security, (l) => l.length,
              zeroCopy: 'none raised'),
        ],
      ),
    );
  }

  static Widget _guardianHealthTile(
      AsyncValue<AdminGuardianState?> g, AsyncValue<bool> can) {
    return g.when(
      loading: () => const AdminNote('Loading…'),
      error: (_, __) => const AdminNote('Unavailable'),
      data: (state) => can.when(
        loading: () => const AdminNote('Loading…'),
        error: (_, __) => const AdminNote('Unavailable'),
        data: (permitted) {
          if (!permitted) {
            return const AdminMetricTile.absent(
                label: 'AI Guardian', absence: MetricAbsence.notAuthorized);
          }
          final healthy = AdminTrustSummary.guardianIsHealthy(state);
          if (healthy == null) {
            // NOT "Active". guardian_state starts empty (169), and the most reassuring
            // reading of missing data is exactly the EC-04 defect.
            return const AdminMetricTile.absent(
                label: 'AI Guardian', absence: MetricAbsence.notRecorded);
          }
          return AdminMetricTile.text(label: 'AI Guardian', display: state!.state!);
        },
      ),
    );
  }

  static Widget _countTile<T>(
    String label,
    AsyncValue<List<T>?> async,
    int Function(List<T>) count, {
    String? zeroCopy,
  }) =>
      async.when(
        loading: () => AdminPlaceholderRow(label: label, text: 'Loading…'),
        error: (_, __) => AdminPlaceholderRow(label: label, text: 'Unavailable'),
        data: (list) => list == null
            ? AdminMetricTile.absent(
                label: label, absence: MetricAbsence.notAuthorized)
            : AdminMetricTile.value(
                label: label, value: count(list), zeroCopy: zeroCopy),
      );

  // ── #ai-guardian ────────────────────────────────────────────────────────
  Widget _aiGuardian(WidgetRef ref) {
    final g = ref.watch(adminGuardianStateProvider);
    final can = ref.watch(adminCanViewGuardianProvider);
    final policies = ref.watch(adminGovernancePoliciesProvider);
    return AdminCard(
      title: 'AI Guardian',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _guardianHealthTile(g, can),
          // A reason is REQUIRED to disable (169 gates it), so showing it is part of
          // showing the state honestly — a Disabled Guardian with no stated reason is
          // itself a finding.
          // A REASON IS PROSE, NOT A STAT. It is rendered as a wrapping footnote rather
          // than a tile value: a disablement reason is the one thing on this card that
          // must not be truncated, and a tile is a single row by design. The first draft
          // put it in a tile and overflowed by 288px, which would have silently clipped
          // why a safety control was switched off.
          g.maybeWhen(
            data: (s) => (s?.isDisabled ?? false)
                ? AdminFootnote('Disabled because: ${s!.reason ?? 'no reason recorded'}')
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          _countTile('Policies', policies, (l) => l.length, zeroCopy: 'None'),
          _countTile('Policies active', policies,
              (l) => l.whereType<AdminGovernancePolicy>().where((p) => p.isActive).length,
              zeroCopy: 'None'),
          const AdminFootnote(
              'Autonomy is re-stated through the governed write path only. Nothing is '
              'changed from this screen.'),
        ],
      ),
    );
  }

  // ── #security, incl. #sec-authz ─────────────────────────────────────────
  Widget _security(WidgetRef ref) {
    final async = ref.watch(adminSecurityEventsProvider);
    return AdminCard(
      title: 'Security',
      child: async.when(
        loading: () => const AdminNote('Loading…'),
        error: (_, __) => const AdminNote('Unavailable'),
        data: (events) {
          if (events == null) {
            return const AdminNote('Not available to your role');
          }
          if (events.isEmpty) return const AdminNote('none raised');
          final denials =
              events.where((e) => e.category == 'authorization_denial').length;
          final auth = events.where((e) => e.category == 'authentication').length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // #sec-authz — the authorization half of the section.
              AdminMetricTile.value(
                  label: 'Authorization denials', value: denials, zeroCopy: 'none raised'),
              AdminMetricTile.value(
                  label: 'Authentication events', value: auth, zeroCopy: 'none raised'),
              const SizedBox(height: AdminDims.space4),
              for (final e in events.take(10)) _EventRow(event: e),
            ],
          );
        },
      ),
    );
  }

  // ── #incidents ──────────────────────────────────────────────────────────
  Widget _incidents(WidgetRef ref) {
    final async = ref.watch(adminIncidentsProvider);
    final canUpdate = ref.watch(adminCanUpdateIncidentsProvider);
    return AdminCard(
      title: 'Incidents',
      child: async.when(
        loading: () => const AdminNote('Loading…'),
        error: (_, __) => const AdminNote('Unavailable'),
        data: (items) {
          if (items == null) return const AdminNote('Not available to your role');
          if (items.isEmpty) return const AdminNote('none open');
          final writable = canUpdate.valueOrNull ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in items.take(10))
                _IncidentRow(incident: i, canUpdate: writable),
              const AdminFootnote(
                  'Evidence and actor identity are withheld from this layer (B-4).'),
              // THE APPROVED READ-ONLY STATE, for a role that may view and not update.
              // It is stated rather than left to be inferred from a missing button.
              if (!writable)
                const AdminFootnote(
                    'Read-only: resolving an incident requires Incidents · update.'),
            ],
          );
        },
      ),
    );
  }

  // ── #audit ──────────────────────────────────────────────────────────────
  Widget _audit(WidgetRef ref) {
    final async = ref.watch(adminAuditEventsProvider);
    return AdminCard(
      title: 'Audit logs',
      child: async.when(
        loading: () => const AdminNote('Loading…'),
        error: (_, __) => const AdminNote('Unavailable'),
        data: (events) {
          if (events == null) return const AdminNote('Not available to your role');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (events.isEmpty)
                const AdminNote('none raised')
              else
                for (final e in events.take(15)) _EventRow(event: e),
              // A13·1 IS STATED, NOT IMPLIED. This ledger is incomplete for whoever is
              // reading it, so absence here is not evidence of absence.
              const AdminFootnote(AdminAuditEvent.a13Note),
            ],
          );
        },
      ),
    );
  }
}

/// One incident. Carries the resolve action only for a caller holding
/// `Incidents·update`, and only behind a confirm dialog — the inventory's Interactions
/// section requires that shape, and recording a resolution is not undoable from here.
class _IncidentRow extends ConsumerWidget {
  const _IncidentRow({required this.incident, required this.canUpdate});

  final AdminIncident incident;
  final bool canUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = incident.resolution != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminDims.space3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incident.summary ?? 'Incident',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.colorTextPrimary,
                      fontSize: AdminDims.typeSmallSize,
                    )),
                Text(
                  [
                    if (incident.severity != null) incident.severity!,
                    if (incident.scope != null) incident.scope!,
                    if (resolved) 'resolved',
                  ].join(' · '),
                  style: const TextStyle(
                    color: AdminColors.colorTextSubtle,
                    fontSize: AdminDims.typeCaptionSize,
                  ),
                ),
              ],
            ),
          ),
          if (canUpdate && !resolved && incident.id != null)
            SizedBox(
              height: AdminDims.sizeControl, // 44px, RESPONSIVE.md
              child: TextButton(
                onPressed: () => _confirm(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: AdminColors.colorBrandAccent,
                  minimumSize:
                      const Size(AdminDims.sizeControl, AdminDims.sizeControl),
                ),
                child: const Text('Resolve',
                    style: TextStyle(
                      fontSize: AdminDims.typeCaptionSize,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.colorBgSurface,
        title: const Text('Record a resolution',
            style: TextStyle(
                color: AdminColors.colorTextPrimary,
                fontSize: AdminDims.typeCardTitleSize)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(incident.summary ?? 'Incident',
                style: const TextStyle(
                    color: AdminColors.colorTextSecondary,
                    fontSize: AdminDims.typeSmallSize)),
            const SizedBox(height: AdminDims.space6),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(
                  color: AdminColors.colorTextPrimary,
                  fontSize: AdminDims.typeSmallSize),
              decoration: const InputDecoration(
                hintText: 'What resolved it',
                hintStyle: TextStyle(color: AdminColors.colorTextMuted),
              ),
            ),
            const SizedBox(height: AdminDims.space4),
            const Text('This is recorded against the incident and audited. It cannot be '
                'undone from this screen.',
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
            child: const Text('Record',
                style: TextStyle(
                    color: AdminColors.colorBrandAccent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(adminTrustServiceProvider).resolveIncident(incident.id!, text);
      ref.invalidate(adminIncidentsProvider);
    } catch (e, st) {
      // THE FAILURE IS SHOWN, AND THE DETAIL GOES TO THE SINK. The governed path
      // re-checks the capability itself and raises 42501; swallowing that into a silent
      // no-op would let an operator believe a resolution was recorded when it was refused
      // — EC-03's defect applied to a write.
      //
      // The operator gets a STABLE SENTENCE, not `$e`. ERR-G2 caught the first version
      // interpolating the raw exception, and it was right to: a Postgres error can carry
      // SQL, identifiers and internal detail, and it tells an operator nothing they can
      // act on. The diagnosable half goes to EC-01's `reportError` sink instead.
      reportError('admin_trust.resolveIncident', e, st,
          {'incident_id': incident.id});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AdminColors.colorBgRaised,
          content: Text(
              'The resolution was not recorded. You may not have permission, or the '
              'incident has changed. Nothing was saved.',
              style: TextStyle(color: AdminColors.colorStatusDangerText)),
        ));
      }
    }
  }
}

/// One audit or security row. It renders the PSEUDONYM and never anything resolved from
/// it — §19.3. There is no code path here that could.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final AdminAuditEvent event;

  @override
  Widget build(BuildContext context) {
    final when = event.occurredAt?.toIso8601String().replaceFirst('T', ' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminDims.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(event.action ?? 'event',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.colorTextPrimary,
                      fontSize: AdminDims.typeSmallSize,
                    )),
              ),
              const SizedBox(width: AdminDims.space4),
              Text(event.outcome ?? '—',
                  style: const TextStyle(
                    color: AdminColors.colorTextMuted,
                    fontSize: AdminDims.typeCaptionSize,
                  )),
            ],
          ),
          Text(
            [
              if (event.category != null) event.category!,
              if (when != null) when.split('.').first,
              // The pseudonym, shown AS a pseudonym and truncated for legibility. It is
              // not a name, and nothing in this layer can turn it into one.
              if (event.subjectPseudonym != null)
                'subject ${event.subjectPseudonym!.substring(0, event.subjectPseudonym!.length.clamp(0, 8))}…',
            ].join(' · '),
            style: const TextStyle(
              color: AdminColors.colorTextSubtle,
              fontSize: AdminDims.typeCaptionSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// `#trust-system` — the state-system panel the design places on Trust, naming the `A11`
/// states this page actually renders rather than illustrating ones it does not.
class _TrustSystemPanel extends StatelessWidget {
  const _TrustSystemPanel();

  @override
  Widget build(BuildContext context) => AdminCard(
        title: 'State system',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            AdminFootnote('Loading · Unavailable · Not available to your role · '
                'Not recorded · Read-only'),
            AdminFootnote('"Not available to your role" and "Not recorded" are different '
                'findings and are never shown interchangeably.'),
            AdminFootnote('This page is read-only. Nothing is changed from this screen.'),
          ],
        ),
      );
}




