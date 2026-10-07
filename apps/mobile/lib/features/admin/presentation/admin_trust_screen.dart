import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import '../domain/admin_trust.dart';
import 'admin_metric_tile.dart';
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
/// IT IS READ-ONLY, AND THAT IS A DESIGN RULE, NOT AN OMISSION. `CONF-D5`'s drawer footer
/// is explicit — *"Actions open the item. Nothing is changed from this screen."* There is
/// no write path on this widget at all, which is the cheapest way to honour that: the
/// Guardian can only be re-stated through `admin_set_guardian_state`, which is gated
/// `AI Guardian·manage` and is not called here. `A10` also bars the Guardian from holding
/// admin authority, so a Trust page that could flip it would be the wrong shape.
///
/// WHAT IT REFUSES TO DO, each a defect this programme has already paid for once:
///   * it never resolves `subject_pseudonym` — §19.3, and the model gives it no way to;
///   * it never presents an unrecorded Guardian state as `Active` — that is EC-04's
///     coercion applied to a safety control;
///   * it states `A13·1` on the audit section rather than implying a complete ledger;
///   * loading, error, "no capability" and "nothing recorded" are four distinct states.
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
    return _Card(
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
      loading: () => const _Note('Loading…'),
      error: (_, __) => const _Note('Unavailable'),
      data: (state) => can.when(
        loading: () => const _Note('Loading…'),
        error: (_, __) => const _Note('Unavailable'),
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
        loading: () => _PlaceholderRow(label: label, text: 'Loading…'),
        error: (_, __) => _PlaceholderRow(label: label, text: 'Unavailable'),
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
    return _Card(
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
                ? _Footnote('Disabled because: ${s!.reason ?? 'no reason recorded'}')
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          _countTile('Policies', policies, (l) => l.length, zeroCopy: 'None'),
          _countTile('Policies active', policies,
              (l) => l.whereType<AdminGovernancePolicy>().where((p) => p.isActive).length,
              zeroCopy: 'None'),
          const _Footnote(
              'Autonomy is re-stated through the governed write path only. Nothing is '
              'changed from this screen.'),
        ],
      ),
    );
  }

  // ── #security, incl. #sec-authz ─────────────────────────────────────────
  Widget _security(WidgetRef ref) {
    final async = ref.watch(adminSecurityEventsProvider);
    return _Card(
      title: 'Security',
      child: async.when(
        loading: () => const _Note('Loading…'),
        error: (_, __) => const _Note('Unavailable'),
        data: (events) {
          if (events == null) {
            return const _Note('Not available to your role');
          }
          if (events.isEmpty) return const _Note('none raised');
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
    return _Card(
      title: 'Incidents',
      child: async.when(
        loading: () => const _Note('Loading…'),
        error: (_, __) => const _Note('Unavailable'),
        data: (items) {
          if (items == null) return const _Note('Not available to your role');
          if (items.isEmpty) return const _Note('none open');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in items.take(10))
                AdminMetricTile.text(
                  label: i.summary ?? 'Incident',
                  display: i.severity ?? '—',
                ),
              const _Footnote(
                  'Evidence and actor identity are withheld from this layer (B-4).'),
            ],
          );
        },
      ),
    );
  }

  // ── #audit ──────────────────────────────────────────────────────────────
  Widget _audit(WidgetRef ref) {
    final async = ref.watch(adminAuditEventsProvider);
    return _Card(
      title: 'Audit logs',
      child: async.when(
        loading: () => const _Note('Loading…'),
        error: (_, __) => const _Note('Unavailable'),
        data: (events) {
          if (events == null) return const _Note('Not available to your role');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (events.isEmpty)
                const _Note('none raised')
              else
                for (final e in events.take(15)) _EventRow(event: e),
              // A13·1 IS STATED, NOT IMPLIED. This ledger is incomplete for whoever is
              // reading it, so absence here is not evidence of absence.
              const _Footnote(AdminAuditEvent.a13Note),
            ],
          );
        },
      ),
    );
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
  Widget build(BuildContext context) => _Card(
        title: 'State system',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _Footnote('Loading · Unavailable · Not available to your role · '
                'Not recorded · Read-only'),
            _Footnote('"Not available to your role" and "Not recorded" are different '
                'findings and are never shown interchangeably.'),
            _Footnote('This page is read-only. Nothing is changed from this screen.'),
          ],
        ),
      );
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AdminDims.space4),
        child: Text(text,
            style: const TextStyle(
              color: AdminColors.colorTextSubtle,
              fontSize: AdminDims.typeCaptionSize,
            )),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AdminDims.space6),
        child: Text(text,
            style: const TextStyle(
              color: AdminColors.colorTextMuted,
              fontSize: AdminDims.typeSmallSize,
            )),
      );
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AdminDims.space7),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AdminColors.colorTextSecondary,
                      fontSize: AdminDims.typeSmallSize)),
            ),
            Text(text,
                style: const TextStyle(
                    color: AdminColors.colorTextSubtle,
                    fontSize: AdminDims.typeSmallSize)),
          ],
        ),
      );
}

/// `COMPONENT-SPECS` › Card.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            vertical: AdminDims.space10, horizontal: AdminDims.space8),
        decoration: BoxDecoration(
          color: AdminColors.colorBgSurface,
          borderRadius: BorderRadius.circular(AdminDims.radiusXl),
          border: Border.all(color: AdminColors.colorLineDefault, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                  color: AdminColors.colorTextMuted,
                  fontSize: AdminDims.typeOverlineSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: AdminDims.typeOverlineSize * 0.12,
                )),
            const SizedBox(height: AdminDims.space4),
            child,
          ],
        ),
      );
}
