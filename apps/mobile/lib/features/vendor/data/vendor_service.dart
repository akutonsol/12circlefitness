import 'package:supabase_flutter/supabase_flutter.dart';

/// Module 15 — Vendor Portal data access.
/// A vendor owns events (vendor_id) and can read / check-in their attendees.
/// RLS (migration 020) enforces ownership; this service just shapes the calls.
class VendorService {
  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  /// Events owned by the signed-in vendor, with a live registration count.
  Future<List<Map<String, dynamic>>> getMyEvents() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _db
        .from('events')
        .select('*, event_registrations(count)')
        .eq('vendor_id', uid)
        .order('event_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    final uid = _uid;
    return await _db.from('events').insert({
      ...data,
      'vendor_id': uid,
    }).select().single();
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    await _db.from('events').update(data).eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.from('events').delete().eq('id', eventId);
  }

  /// Attendees for one of the vendor's events (joined to their profile).
  Future<List<Map<String, dynamic>>> getRegistrations(String eventId) async {
    final data = await _db
        .from('event_registrations')
        .select(
            'id, status, checked_in_at, registered_at, ticket_code, user_id, '
            'user_profiles(first_name, last_name, email, avatar_url)')
        .eq('event_id', eventId)
        .order('registered_at');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> setCheckedIn(String registrationId, bool checkedIn) async {
    await _db.from('event_registrations').update({
      'checked_in_at': checkedIn ? DateTime.now().toIso8601String() : null,
      'status': checkedIn ? 'attended' : 'registered',
    }).eq('id', registrationId);
  }
}
