import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final platformStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getPlatformStats();
});

final recentUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminServiceProvider).getRecentUsers();
});
