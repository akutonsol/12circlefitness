import 'package:supabase_flutter/supabase_flutter.dart';

/// Module 25 — Admin Dashboard data access.
/// Backed by SECURITY DEFINER RPCs (`admin_platform_stats`, `admin_recent_users`)
/// that enforce role='admin' server-side, so no broad RLS is loosened.
class AdminService {
  final _db = Supabase.instance.client;

  Future<Map<String, dynamic>> getPlatformStats() async {
    final res = await _db.rpc('admin_platform_stats');
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  Future<List<Map<String, dynamic>>> getRecentUsers({int limit = 20}) async {
    final res = await _db.rpc('admin_recent_users', params: {'p_limit': limit});
    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
