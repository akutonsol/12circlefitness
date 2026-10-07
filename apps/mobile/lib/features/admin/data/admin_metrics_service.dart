import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_metrics.dart';

/// V5 §163 — data access for the owner-approved Admin metric surfaces
/// (migrations 171–173).
///
/// WHY THESE ARE VIEW READS AND NOT RPCs. The existing [AdminService] calls
/// `admin_platform_stats()`, which is gated on `is_admin()` alone — one
/// cross-area gate for every figure on the dashboard. These surfaces are gated
/// PER AREA inside each view's own `WHERE`, against the approved capability
/// matrix, so a `content_editor` sees the Users panel and not the revenue panel
/// without the service having to know anything about roles.
///
/// WHY EVERY METHOD RETURNS A NULLABLE MODEL. A view whose `WHERE` fails returns
/// NO ROW, not an error and not zeros. `maybeSingle()` surfaces that as null,
/// which the UI renders as the approved `A11` state. Translating it into an empty
/// model full of zeros would tell an unauthorized viewer that the platform has no
/// users, no revenue and no events — a false statement, and for METRIC-02 an
/// inference about the audit population.
class AdminMetricsService {
  AdminMetricsService({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  Future<AdminActivityOverview?> getActivityOverview() async =>
      _one('admin_activity_overview', AdminActivityOverview.fromRow);

  Future<AdminUserOverview?> getUserOverview() async =>
      _one('admin_user_overview', AdminUserOverview.fromRow);

  Future<AdminEventsOverview?> getEventsOverview() async =>
      _one('admin_events_overview', AdminEventsOverview.fromRow);

  Future<AdminCommunityOverview?> getCommunityOverview() async =>
      _one('admin_community_overview', AdminCommunityOverview.fromRow);

  Future<AdminRevenueOverview?> getRevenueOverview() async =>
      _one('admin_revenue_overview', AdminRevenueOverview.fromRow);

  /// METRIC-11. Returns null when no release has been recorded for the
  /// environment — which is the current state, because the CI ingestion path is
  /// gated on `P10`/`CONF-D9` and is not built. The card renders `A11`.
  Future<AdminReleaseStatus?> getReleaseStatus() async =>
      _one('admin_release_status', AdminReleaseStatus.fromRow);

  Future<T?> _one<T>(
    String view,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final row = await _db.from(view).select().maybeSingle();
    if (row == null) return null;
    return parse(Map<String, dynamic>.from(row));
  }
}
