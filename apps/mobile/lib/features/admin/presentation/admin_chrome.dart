import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_tokens.dart';

/// V5 §184 — the shared Admin container chrome.
///
/// Extracted because it had been written three times with three names — `_AdminCard` in
/// the metrics panel, `_Card` in the attention queue and again in the Trust screen — and
/// the approved IA has **six pages**, so the next four would have copied it four more
/// times. Three copies of a card is tolerable; seven is how one page quietly stops
/// matching `COMPONENT-SPECS` while the others still do.
///
/// Anatomy is the published spec (`COMPONENT-SPECS.md` › Card):
/// `--adm-color-bg-surface`, `--adm-radius-xl`, and a hairline in
/// `--adm-color-line-default` standing in for `--adm-shadow-edge`'s inset ring, which
/// Flutter has no equivalent for. Every value comes from [AdminColors] / [AdminDims],
/// which are generated from `admin.tokens.css` at `931218b` — so there is no raw hex in
/// the Admin presentation layer outside the generated token file itself.
class AdminCard extends StatelessWidget {
  const AdminCard({required this.title, required this.child, super.key});

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
                  // --adm-type-overline-tracking: 0.12em, computed from the token size.
                  letterSpacing: AdminDims.typeOverlineSize * 0.12,
                )),
            const SizedBox(height: AdminDims.space4),
            child,
          ],
        ),
      );
}

/// A single muted line standing in for a card's whole body — the `A11` Loading,
/// Unavailable, permission-denied and zero states.
///
/// It takes the copy from its caller on purpose. The approved design's zero wording
/// differs by surface — *"None"*, *"none raised"*, *"none open"* — and a widget that
/// picked one would impose it everywhere.
class AdminNote extends StatelessWidget {
  const AdminNote(this.text, {super.key});

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

/// Secondary prose under a card — a limit the surface is stating about itself, such as
/// `A13·1`'s exclusion or `B-4`'s withheld fields. It WRAPS, because the things said here
/// are sentences and must not be truncated (§183.3).
class AdminFootnote extends StatelessWidget {
  const AdminFootnote(this.text, {super.key});

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

/// A labelled row whose value is a STATE rather than a figure — Loading, Unavailable.
///
/// Deliberately not an `AdminMetricTile`: loading and error are not metric absences, and
/// conflating them would let a transient network failure read as a permission boundary.
class AdminPlaceholderRow extends StatelessWidget {
  const AdminPlaceholderRow({required this.label, required this.text, super.key});

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
            const SizedBox(width: AdminDims.space4),
            Flexible(
              child: Text(text,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AdminColors.colorTextSubtle,
                      fontSize: AdminDims.typeSmallSize)),
            ),
          ],
        ),
      );
}

/// Renders an action area according to a CAPABILITY CHECK THAT CAN ITSELF FAIL.
///
/// WHY THIS EXISTS. The first versions of the Trust, Ecosystem and event-authoring actions
/// read their capability with `.valueOrNull ?? false`. `EC-G8` flagged it and was right:
/// on a provider that does I/O — and `admin_can` is an RPC over the network — that
/// converts *"could not load"* into the domain's empty value at the read site. Here the
/// empty value is `false`, which the UI renders as **"Read-only: this requires X"**.
///
/// So a failed capability check told an operator they **lack a permission they may well
/// hold**. That is the same defect as EC-04's green `LOW RISK` badge — "the read failed"
/// and "the answer is no" rendered as one pixel — applied to authorization.
///
/// Four states, kept apart:
///   * **loading** — the check has not answered yet;
///   * **failed** — the check itself could not be made, which is NOT a denial;
///   * **true** — the action;
///   * **false** — the approved read-only state, which is a real answer.
Widget adminCapabilityGate(
  AsyncValue<bool> capability, {
  required Widget Function() allowed,
  required Widget denied,
  String checking = 'Checking your permissions…',
  String failed = 'Your permissions could not be checked. No action is offered, and this '
      'is not a denial.',
}) =>
    capability.when(
      loading: () => AdminFootnote(checking),
      error: (_, __) => AdminFootnote(failed),
      data: (can) => can ? allowed() : denied,
    );
