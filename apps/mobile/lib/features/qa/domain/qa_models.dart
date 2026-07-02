// Shared model for the in-app QA Center. A QaSuite is one testable area of the
// platform; it runs live (read-only, as the current user) against Supabase and
// returns a set of QaChecks. The dashboard orchestrates suites and renders the
// results — it never re-implements the check logic itself.
import 'package:supabase_flutter/supabase_flutter.dart';

enum QaStatus { idle, running, pass, warn, fail, skip }

extension QaStatusX on QaStatus {
  bool get isTerminal => this == QaStatus.pass || this == QaStatus.warn ||
      this == QaStatus.fail || this == QaStatus.skip;

  /// Roll a set of statuses up into one (fail dominates, then warn, then pass).
  static QaStatus rollup(Iterable<QaStatus> xs) {
    if (xs.isEmpty) return QaStatus.skip;
    if (xs.contains(QaStatus.fail)) return QaStatus.fail;
    if (xs.contains(QaStatus.running)) return QaStatus.running;
    if (xs.every((s) => s == QaStatus.skip)) return QaStatus.skip;
    if (xs.contains(QaStatus.warn)) return QaStatus.warn;
    return QaStatus.pass;
  }
}

/// One assertion within a suite.
class QaCheck {
  final String name;
  final QaStatus status;
  final String detail;   // count, latency note, or the reason it failed/skipped
  final int ms;          // execution time
  final double? value;   // optional 0..1 completion (drives progress bars)
  const QaCheck(this.name, this.status, [this.detail = '', this.ms = 0, this.value]);
}

/// The outcome of running one suite.
class QaSuiteResult {
  final String suite;
  final List<QaCheck> checks;
  final int ms;
  const QaSuiteResult(this.suite, this.checks, this.ms);

  QaStatus get status => QaStatusX.rollup(checks.map((c) => c.status));
  int get total => checks.length;
  int get passed => checks.where((c) =>
      c.status == QaStatus.pass || c.status == QaStatus.warn || c.status == QaStatus.skip).length;
}

/// A testable area of the app. Implementations are pure orchestration over the
/// live Supabase client — the single source of business truth stays in the app
/// (e.g. ClientPlanCaps) and in the CLI harnesses.
abstract class QaSuite {
  String get name;
  String get group;       // which health-card bucket this rolls up into
  Future<QaSuiteResult> run(SupabaseClient db);
}

/// Helper: time an async probe and turn it into a QaCheck.
Future<QaCheck> timedCheck(
  String name,
  Future<QaCheck> Function() body,
) async {
  final sw = Stopwatch()..start();
  try {
    final c = await body();
    return QaCheck(c.name, c.status, c.detail, c.ms == 0 ? sw.elapsedMilliseconds : c.ms);
  } catch (e) {
    return QaCheck(name, QaStatus.fail, _short(e), sw.elapsedMilliseconds);
  }
}

String _short(Object e) {
  final s = e.toString().replaceAll('\n', ' ');
  return s.length > 90 ? '${s.substring(0, 90)}…' : s;
}
