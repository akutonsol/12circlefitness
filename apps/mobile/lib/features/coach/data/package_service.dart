import 'package:supabase_flutter/supabase_flutter.dart';

/// Coach packages (per-session / bulk / monthly) + client workout schedules.
class PackageService {
  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── Coach packages ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMyPackages() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _db
        .from('coach_packages')
        .select()
        .eq('coach_id', uid);
    final list = List<Map<String, dynamic>>.from(data);
    sortForDisplay(list);
    return list;
  }

  Future<List<Map<String, dynamic>>> getCoachPackages(String coachId) async {
    final data = await _db
        .from('coach_packages')
        .select()
        .eq('coach_id', coachId)
        .eq('active', true);
    final list = List<Map<String, dynamic>>.from(data);
    sortForDisplay(list);
    return list;
  }

  /// Groups packages by type so they sit together under each other:
  /// Monthly plans (Basic→Premium→VIP) → Session packages (larger first, so a
  /// Signature 4-pack falls under a Performance 8-pack) → Per-session.
  static void sortForDisplay(List<Map<String, dynamic>> list) {
    int groupRank(String t) => switch (t) { 'monthly' => 0, 'bulk' => 1, _ => 2 };
    list.sort((a, b) {
      final ta = a['type'] as String? ?? '';
      final tb = b['type'] as String? ?? '';
      final g = groupRank(ta).compareTo(groupRank(tb));
      if (g != 0) return g;
      final pa = (a['price'] as num?)?.toDouble() ?? 0;
      final pb = (b['price'] as num?)?.toDouble() ?? 0;
      if (ta == 'bulk') {
        // Larger packs first (by sessions, then price) so smaller fall under them.
        final sa = (a['sessions'] as num?)?.toInt() ?? 0;
        final sb = (b['sessions'] as num?)?.toInt() ?? 0;
        if (sa != sb) return sb.compareTo(sa);
        return pb.compareTo(pa);
      }
      // Monthly + per-session: cheapest first (natural upgrade path).
      return pa.compareTo(pb);
    });
  }

  Future<void> savePackage({
    String? id,
    required String type,
    required String name,
    required int sessions,
    required double price,
    String? description,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final payload = {
      'coach_id': uid,
      'type': type,
      'name': name,
      'sessions': sessions,
      'price': price,
      'description': description,
    };
    if (id == null) {
      await _db.from('coach_packages').insert(payload);
    } else {
      await _db.from('coach_packages').update(payload).eq('id', id);
    }
  }

  Future<void> deletePackage(String id) async {
    try {
      await _db.from('coach_packages').delete().eq('id', id);
    } catch (_) {
      // A client schedule may reference it (FK) — deactivate instead.
      await _db.from('coach_packages').update({'active': false}).eq('id', id);
    }
  }

  static const sessionTiers = [4, 8, 12, 16];

  /// The coach's current session-package tiers, keyed by session count, each
  /// with its OWN name / price / description.
  Future<Map<int, ({String name, double price, String description})>> getSessionTiers() async {
    final uid = _uid;
    if (uid == null) return {};
    final rows = await _db
        .from('coach_packages')
        .select('sessions, price, name, description')
        .eq('coach_id', uid)
        .eq('type', 'bulk');
    return {
      for (final r in rows as List)
        (r['sessions'] as num).toInt(): (
          name: r['name'] as String? ?? '',
          price: (r['price'] as num?)?.toDouble() ?? 0,
          description: r['description'] as String? ?? '',
        ),
    };
  }

  /// Saves the four session-package tiers (4/8/12/16) — each with its own
  /// name + price + description. A tier with price <= 0 is removed/deactivated.
  Future<void> saveSessionTiers(
      Map<int, ({String name, double price, String description})> tiers) async {
    final uid = _uid;
    if (uid == null) return;
    final existing = await _db
        .from('coach_packages')
        .select('id, sessions')
        .eq('coach_id', uid)
        .eq('type', 'bulk');
    final byTier = {
      for (final r in existing as List) (r['sessions'] as num).toInt(): r['id'] as String,
    };
    for (final tier in sessionTiers) {
      final data = tiers[tier];
      final id = byTier[tier];
      if (data == null || data.price <= 0) {
        if (id != null) await deletePackage(id);
        continue;
      }
      final payload = {
        'coach_id': uid, 'type': 'bulk', 'sessions': tier,
        'price': data.price, 'active': true,
        'name': data.name.trim().isEmpty ? '$tier-Session Pack' : data.name.trim(),
        'description': data.description.trim().isEmpty ? null : data.description.trim(),
      };
      if (id != null) {
        await _db.from('coach_packages').update(payload).eq('id', id);
      } else {
        await _db.from('coach_packages').insert(payload);
      }
    }
  }

  // ── Client schedule ───────────────────────────────────────
  Future<Map<String, dynamic>?> getMySchedule() async {
    final uid = _uid;
    if (uid == null) return null;
    return await _db
        .from('client_schedules')
        .select()
        .eq('client_id', uid)
        .maybeSingle();
  }

  /// Client's onboarding-chosen training days/week (to seed the schedule).
  Future<int> getOnboardingTrainingDays() async {
    final uid = _uid;
    if (uid == null) return 0;
    final row = await _db
        .from('user_profiles')
        .select('training_days_per_week')
        .eq('id', uid)
        .maybeSingle();
    return (row?['training_days_per_week'] as num?)?.toInt() ?? 0;
  }

  Future<void> saveSchedule({
    required String coachId,
    String? packageId,
    required List<String> days,
    required String sessionTime,
    Map<String, String>? dayTimes,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('client_schedules').upsert({
      'client_id': uid,
      'coach_id': coachId,
      'package_id': packageId,
      'days': days,
      'session_time': sessionTime,
      'day_times': dayTimes ?? {},
    }, onConflict: 'client_id');
  }

  /// Coach: a specific client's schedule.
  Future<Map<String, dynamic>?> getClientSchedule(String clientId) async {
    return await _db
        .from('client_schedules')
        .select()
        .eq('client_id', clientId)
        .maybeSingle();
  }
}
