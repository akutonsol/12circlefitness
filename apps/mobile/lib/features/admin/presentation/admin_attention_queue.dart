import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_metrics.dart';
import '../domain/admin_provider.dart';
import 'admin_tokens.dart';

/// `DESIGN-01` §1 — the `critical-incident` state, implemented.
///
/// `STATE-SPECS-A11.md` §1 records **"No dependency. Every element exists"** for this
/// state: `audit_incidents.severity` already ships `Critical`, and `admin_incidents`
/// (migration 160) already projects `severity` to the Admin layer. So this is
/// implementation of an approved design, not a new product decision.
///
/// WHAT THE SPECIFICATION REQUIRES, AND IS IMPLEMENTED HERE.
///   * severity label `Critical` in **title case** — the shipped `A2` enum (`143:70`).
///     METRIC-12 established by evidence that an uppercase `CRITICAL` appears nowhere,
///     so nothing upper-cases it;
///   * the card container — `--adm-color-bg-surface`, `--adm-radius-xl`, hairline ring;
///   * a status pill badge — `--adm-radius-pill`, `--adm-font-weight-semibold`, tracked;
///   * the zero state as the **literal copy the design uses** — "none raised" — and
///     explicitly *not* an empty panel;
///   * **a single primary action per item, never bulk**;
///   * the read-only footer, verbatim: *"Actions open the item. Nothing is changed
///     from this screen."*;
///   * a 44px touch target (`--adm-size-control`) per `RESPONSIVE.md`.
///
/// TWO DEVIATIONS FROM THE OBSERVED DESIGN, NAMED RATHER THAN HIDDEN.
///
/// 1. **Badge colour.** `COMPONENT-SPECS` › Severity badge records the observed colour
///    as `#f08a9b`, marked with no token. That value appears **nowhere** in
///    `admin.tokens.css` — it is untokenised. This uses `--adm-color-status-danger-text`
///    (`#f07a8c`) instead, for two reasons: the Helix rule forbids a component holding
///    raw hex, and `admin.contrast.md` publishes a **measured 7.4:1** ratio for the
///    token while `#f08a9b` carries no measurement at all. The two are visually
///    near-identical. The discrepancy is recorded in V5 §168, not resolved by
///    declaring the design wrong.
///
/// 2. **Icon.** The specification names `ph-fill ph-warning-circle` from the Phosphor
///    set. **The app does not depend on Phosphor** — `pubspec.yaml` carries only
///    `cupertino_icons` — so a Material fill-weight equivalent is substituted. This is
///    a substitution, not fidelity, and adding an icon dependency is not a decision to
///    take in passing.
///
/// Two further untokenised values are followed where they are safe and recorded where
/// they are not: the badge's `11.5px` font size has no token (the nearest are 11px and
/// 12px), and its `0.08em` tracking is not the `0.12em` overline token. The nearest
/// published token is used for the size, and the tracking is expressed as the exact
/// `0.08em` the design specifies, computed from the font size.
class AdminAttentionQueue extends ConsumerWidget {
  const AdminAttentionQueue({super.key});

  /// The design's own wording for the zero case, on three separate pages.
  static const zeroCopy = 'none raised';

  /// `CONF-D5` README, quoted exactly.
  static const readOnlyFooter =
      'Actions open the item. Nothing is changed from this screen.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminIncidentsProvider);
    return _Card(
      title: 'Needs your attention',
      child: async.when(
        loading: () => const _Note('Loading…'),
        error: (_, __) => const _Note('Unavailable'),
        data: (items) {
          // Null and empty are different facts, and the service distinguishes them by
          // asking admin_can rather than inferring a permission from an empty list.
          if (items == null) return const _Note('Not available to your role');
          if (items.isEmpty) return const _Note(zeroCopy);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in items) _IncidentRow(incident: i),
              const SizedBox(height: AdminDims.space6),
              const Text(readOnlyFooter,
                  style: TextStyle(
                    color: AdminColors.colorTextSubtle,
                    fontSize: AdminDims.typeCaptionSize,
                  )),
            ],
          );
        },
      ),
    );
  }
}

/// One queue item. Opening it reveals what is already recorded and changes nothing —
/// there is no write path on this widget at all, which is the cheapest way to honour
/// "nothing is changed from this screen".
class _IncidentRow extends StatefulWidget {
  const _IncidentRow({required this.incident});

  final AdminIncident incident;

  @override
  State<_IncidentRow> createState() => _IncidentRowState();
}

class _IncidentRowState extends State<_IncidentRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.incident;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminDims.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                // See the class doc: a Material substitution for ph-fill
                // ph-warning-circle, because Phosphor is not a dependency.
                Icons.error_rounded,
                size: AdminDims.sizeIconMd,
                color: _severityColor(i.severity),
              ),
              const SizedBox(width: AdminDims.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i.severity != null) _SeverityBadge(severity: i.severity!),
                    if (i.severity != null) const SizedBox(height: AdminDims.space2),
                    Text(
                      i.summary ?? 'Incident',
                      style: const TextStyle(
                        color: AdminColors.colorTextPrimary,
                        fontSize: AdminDims.typeSmallSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AdminDims.space1),
                    Text(
                      [
                        if (i.scope != null) i.scope!,
                        if (i.occurredAt != null)
                          i.occurredAt!.toIso8601String().split('T').first,
                      ].join(' · '),
                      style: const TextStyle(
                        color: AdminColors.colorTextMuted,
                        fontSize: AdminDims.typeCaptionSize,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AdminDims.space4),
              // A SINGLE primary action per item. There is deliberately no select-all,
              // no multi-select and no bulk control: the specification says "never
              // bulk", and a bulk affordance on a read-only surface would also imply a
              // mutation that does not exist.
              if (i.hasDetail)
                SizedBox(
                  height: AdminDims.sizeControl, // 44px touch target, RESPONSIVE.md
                  child: TextButton(
                    onPressed: () => setState(() => _open = !_open),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminColors.colorBrandAccent,
                      minimumSize: const Size(
                          AdminDims.sizeControl, AdminDims.sizeControl),
                    ),
                    child: Text(_open ? 'Close' : 'Investigate',
                        style: const TextStyle(
                          fontSize: AdminDims.typeCaptionSize,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: AdminDims.space4),
            for (final row in <(String, String?)>[
              ('Suspected cause', i.suspectedCause),
              ('Recommended action', i.recommendedAction),
              ('Action taken', i.actionTaken),
              ('Resolution', i.resolution),
            ])
              if (row.$2 != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AdminDims.space3),
                  child: Text('${row.$1}: ${row.$2}',
                      style: const TextStyle(
                        color: AdminColors.colorTextSecondary,
                        fontSize: AdminDims.typeCaptionSize,
                      )),
                ),
          ],
        ],
      ),
    );
  }
}

/// `COMPONENT-SPECS` › Severity badge, over the shipped `A2` scale.
class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AdminDims.space4, vertical: AdminDims.space1),
          decoration: BoxDecoration(
            color: _severityTint(severity),
            borderRadius: BorderRadius.circular(AdminDims.radiusPill),
          ),
          child: Text(
            // Title case, exactly as the shipped enum stores it.
            severity,
            style: TextStyle(
              color: _severityColor(severity),
              // The spec's 11.5px has no token; typeOverlineSize (11px) is the
              // nearest published value. Deviation recorded in V5 §168.
              fontSize: AdminDims.typeOverlineSize,
              fontWeight: FontWeight.w600, // --adm-font-weight-semibold
              letterSpacing: AdminDims.typeOverlineSize * 0.08, // the spec's 0.08em
            ),
          ),
        ),
      );
}

Color _severityColor(String? severity) => switch (severity) {
      'Critical' => AdminColors.colorStatusDangerText,
      'High' => AdminColors.colorStatusWarningText,
      'Warning' => AdminColors.colorStatusWarningText,
      // Informational, and anything the enum gains later. An unrecognised severity
      // is rendered neutrally rather than guessed into a danger colour.
      _ => AdminColors.colorTextMuted,
    };

Color _severityTint(String? severity) => switch (severity) {
      'Critical' => AdminColors.colorStatusDangerTint,
      'High' => AdminColors.colorStatusWarningTint,
      'Warning' => AdminColors.colorStatusWarningTint,
      _ => AdminColors.colorBgInset,
    };

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
