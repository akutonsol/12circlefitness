import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_metrics_service.dart';
import '../data/admin_service.dart';
import 'admin_metrics.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final platformStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getPlatformStats();
});

final recentUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminServiceProvider).getRecentUsers();
});

// ── V5 §163 · the owner-approved metric surfaces (migrations 171-173) ───────
// Each provider yields a NULLABLE model. Null means "this area's surface
// returned no row" — the caller holds no capability for it — and the UI renders
// the approved A11 empty state. None of these providers substitutes an empty
// model, because zeros would assert measurements nobody is authorized to see.

final adminMetricsServiceProvider =
    Provider<AdminMetricsService>((ref) => AdminMetricsService());

final adminActivityOverviewProvider =
    FutureProvider<AdminActivityOverview?>((ref) async =>
        ref.watch(adminMetricsServiceProvider).getActivityOverview());

final adminUserOverviewProvider = FutureProvider<AdminUserOverview?>(
    (ref) async => ref.watch(adminMetricsServiceProvider).getUserOverview());

final adminEventsOverviewProvider = FutureProvider<AdminEventsOverview?>(
    (ref) async => ref.watch(adminMetricsServiceProvider).getEventsOverview());

final adminCommunityOverviewProvider =
    FutureProvider<AdminCommunityOverview?>((ref) async =>
        ref.watch(adminMetricsServiceProvider).getCommunityOverview());

final adminRevenueOverviewProvider = FutureProvider<AdminRevenueOverview?>(
    (ref) async => ref.watch(adminMetricsServiceProvider).getRevenueOverview());

final adminReleaseStatusProvider = FutureProvider<AdminReleaseStatus?>(
    (ref) async => ref.watch(adminMetricsServiceProvider).getReleaseStatus());

/// `DESIGN-01` §1 · the attention queue. Null means no `Incidents·view`; an empty
/// list means authorized with nothing raised, which the design renders with its own
/// literal copy rather than as a blank panel.
final adminIncidentsProvider = FutureProvider<List<AdminIncident>?>(
    (ref) async => ref.watch(adminMetricsServiceProvider).getIncidents());
