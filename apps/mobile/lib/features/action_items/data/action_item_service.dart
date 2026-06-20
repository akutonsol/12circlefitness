import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/action_item.dart';

/// Client Action Items — the coach-driven task system.
/// Notifications (assigned → client, completed → coach) are handled by DB
/// triggers in migration 017, so this service only owns the data operations.
class ActionItemService {
  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  /// Client: their assigned items, newest/most-urgent first.
  Future<List<ActionItem>> getMyActionItems() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final data = await _db
          .from('action_items')
          .select()
          .eq('client_id', uid)
          .order('status') // pending before completed
          .order('due_date', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false);
      return (data as List)
          .map((m) => ActionItem.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Coach: items assigned to a specific client.
  Future<List<ActionItem>> getClientActionItems(String clientId) async {
    try {
      final data = await _db
          .from('action_items')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((m) => ActionItem.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Coach: assign a new action item to a client (ACT-001).
  Future<bool> assignActionItem({
    required String clientId,
    required String title,
    String description = '',
    String category = 'daily',
    int points = 10,
    DateTime? dueDate,
  }) async {
    final coachId = _uid;
    if (coachId == null) return false;
    try {
      await _db.from('action_items').insert({
        'client_id': clientId,
        'coach_id': coachId,
        'title': title,
        'description': description,
        'category': category,
        'points': points,
        'created_by': 'coach',
        'status': 'pending',
        'due_date': dueDate?.toIso8601String().split('T').first,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Client: mark an item complete, optionally with proof + notes (ACT-002).
  /// The coach notification fires from the DB trigger.
  Future<bool> completeActionItem(
    String id, {
    String? proofUrl,
    String? notes,
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db.from('action_items').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        if (proofUrl != null) 'proof_url': proofUrl,
        if (notes != null) 'client_notes': notes,
      }).eq('id', id).eq('client_id', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Client: reopen a completed item.
  Future<void> reopen(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('action_items').update({
      'status': 'pending',
      'completed_at': null,
    }).eq('id', id).eq('client_id', uid);
  }

  /// Coach: completion stats for the dashboard view (assigned / completed / %).
  Future<({int assigned, int completed, double rate})> completionStats(
      String clientId) async {
    final items = await getClientActionItems(clientId);
    final assigned = items.length;
    final completed = items.where((i) => i.isCompleted).length;
    final rate = assigned == 0 ? 0.0 : completed / assigned;
    return (assigned: assigned, completed: completed, rate: rate);
  }
}
