import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  final supabase = Supabase.instance.client;

  // ── Conversations ─────────────────────────────────────────────────────────
  // Table schema: id, participant_1, participant_2, last_message, last_message_at

  /// Returns all conversations for the current user, each enriched with the
  /// other participant's profile from user_profiles.
  Future<List<Map<String, dynamic>>> getConversations() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final convs = await supabase
          .from('conversations')
          .select('id, participant_1, participant_2, last_message, last_message_at')
          .or('participant_1.eq.$userId,participant_2.eq.$userId')
          .order('last_message_at', ascending: false);

      if ((convs as List).isEmpty) return [];

      final otherIds = convs.map<String>((c) =>
        c['participant_1'] == userId
          ? c['participant_2'] as String
          : c['participant_1'] as String
      ).toSet().toList();

      final profiles = await supabase
          .from('user_profiles')
          .select('id, first_name, last_name, role, avatar_url')
          .inFilter('id', otherIds);

      final profileMap = <String, Map<String, dynamic>>{
        for (final p in profiles) p['id'] as String: p,
      };

      return convs.map<Map<String, dynamic>>((c) {
        final otherId = c['participant_1'] == userId
            ? c['participant_2'] as String
            : c['participant_1'] as String;
        return {
          ...Map<String, dynamic>.from(c),
          'participant': profileMap[otherId],
        };
      }).toList();
    } catch (e) {
      print('getConversations error: $e');
      return [];
    }
  }

  /// For a CLIENT: finds or creates a conversation with the first available coach.
  Future<String?> getOrCreateClientCoachConversation() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      // Message the client's ASSIGNED coach — the active (accepted) relationship,
      // most recently activated — NOT just the first coach on the platform.
      final rel = await supabase
          .from('coach_client_relationships')
          .select('coach_id')
          .eq('client_id', userId)
          .eq('status', 'active')
          .order('activated_at', ascending: false, nullsFirst: false)
          .limit(1)
          .maybeSingle();
      final coachId = rel?['coach_id'] as String?;
      if (coachId == null) return null; // no accepted coach yet
      return getOrCreateConversationWith(coachId);
    } catch (e) {
      print('getOrCreateClientCoachConversation error: $e');
      return null;
    }
  }

  /// Finds (or creates) the 1:1 conversation between the current user and a
  /// specific other participant (e.g. a chosen coach).
  Future<String?> getOrCreateConversationWith(String otherUserId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      // Only a conversation between exactly these two participants.
      final existing = await supabase
          .from('conversations')
          .select('id')
          .or('and(participant_1.eq.$userId,participant_2.eq.$otherUserId),'
              'and(participant_1.eq.$otherUserId,participant_2.eq.$userId)')
          .limit(1);
      if ((existing as List).isNotEmpty) return existing.first['id'] as String;

      final result = await supabase
          .from('conversations')
          .insert({
            'participant_1': userId,
            'participant_2': otherUserId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      return result['id'] as String;
    } catch (e) {
      print('getOrCreateConversationWith error: $e');
      return null;
    }
  }

  /// For a COACH: finds or creates a conversation with a specific client.
  Future<String?> getOrCreateCoachClientConversation(String clientId) async {
    final coachId = supabase.auth.currentUser?.id;
    if (coachId == null) return null;
    try {
      // Check both orderings since the table has no role constraint
      final existing = await supabase
          .from('conversations')
          .select('id')
          .or(
            'and(participant_1.eq.$coachId,participant_2.eq.$clientId),'
            'and(participant_1.eq.$clientId,participant_2.eq.$coachId)'
          )
          .limit(1);
      if ((existing as List).isNotEmpty) return existing.first['id'] as String;

      final result = await supabase
          .from('conversations')
          .insert({
            'participant_1': coachId,
            'participant_2': clientId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      return result['id'] as String;
    } catch (e) {
      print('getOrCreateCoachClientConversation error: $e');
      return null;
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content,
        'is_read': false,
        'sent_at': DateTime.now().toIso8601String(),
      };
      if (metadata != null) row['metadata'] = metadata;
      await supabase.from('messages').insert(row);
      await supabase.from('conversations').update({
        'last_message': content,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);
      // Recipient notification is handled server-side by the
      // trg_notify_on_message DB trigger (MSG-003) — no Dart-side insert here,
      // otherwise the recipient would get two notifications per message.
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final data = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('sent_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> messagesStream(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('sent_at');
  }

  Future<void> markAsRead(String conversationId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
    } catch (e) {
      print('markAsRead error: $e');
    }
  }

  Future<int> getUnreadCount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    try {
      final convs = await supabase
          .from('conversations')
          .select('id')
          .or('participant_1.eq.$userId,participant_2.eq.$userId');
      if ((convs as List).isEmpty) return 0;
      final convIds = convs.map((c) => c['id']).toList();

      final data = await supabase
          .from('messages')
          .select('id')
          .eq('is_read', false)
          .neq('sender_id', userId)
          .inFilter('conversation_id', convIds);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  List<Map<String, dynamic>> getSampleMessages() {
    final now = DateTime.now();
    return [
      {'id': '1', 'sender_id': 'coach', 'content': "Hey! How are you feeling after yesterday's workout?", 'sent_at': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(), 'is_read': true},
      {'id': '2', 'sender_id': 'me', 'content': 'A bit sore but in a good way! The hip thrusts really hit different 😅', 'sent_at': now.subtract(const Duration(days: 1, hours: 1)).toIso8601String(), 'is_read': true},
      {'id': '3', 'sender_id': 'coach', 'content': "That's exactly what we want! Make sure you're hitting your protein today for recovery.", 'sent_at': now.subtract(const Duration(hours: 3)).toIso8601String(), 'is_read': true},
      {'id': '4', 'sender_id': 'coach', 'content': 'Focus on hitting your protein goal today. Your strength numbers will thank you tomorrow.', 'sent_at': now.subtract(const Duration(minutes: 5)).toIso8601String(), 'is_read': false},
    ];
  }
}
