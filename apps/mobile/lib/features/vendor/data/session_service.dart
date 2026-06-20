import 'package:supabase_flutter/supabase_flutter.dart';

/// Module 14 — Speaker / Session Management.
/// Sessions form an event's agenda. Public-read; only the owning vendor writes
/// (enforced by RLS in migration 021).
class SessionService {
  final _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSessions(String eventId) async {
    final data = await _db
        .from('event_sessions')
        .select()
        .eq('event_id', eventId)
        .order('sort_order')
        .order('starts_at', ascending: true, nullsFirst: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addSession(String eventId, Map<String, dynamic> data) async {
    await _db.from('event_sessions').insert({...data, 'event_id': eventId});
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> data) async {
    await _db.from('event_sessions').update(data).eq('id', sessionId);
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.from('event_sessions').delete().eq('id', sessionId);
  }
}
