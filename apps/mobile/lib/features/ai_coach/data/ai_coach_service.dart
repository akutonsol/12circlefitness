import 'package:supabase_flutter/supabase_flutter.dart';

enum AICoachMode { nutrition, workout, general, checkinAnalysis, riskDetection }

extension AICoachModeExt on AICoachMode {
  String get value => switch (this) {
    AICoachMode.nutrition => 'nutrition',
    AICoachMode.workout => 'workout',
    AICoachMode.general => 'general',
    AICoachMode.checkinAnalysis => 'checkin_analysis',
    AICoachMode.riskDetection => 'risk_detection',
  };
  String get label => switch (this) {
    AICoachMode.nutrition => 'Nutrition',
    AICoachMode.workout => 'Workout',
    AICoachMode.general => 'General',
    AICoachMode.checkinAnalysis => 'Check-In Analysis',
    AICoachMode.riskDetection => 'Risk Detection',
  };
  String get emoji => switch (this) {
    AICoachMode.nutrition => '🥗',
    AICoachMode.workout => '💪',
    AICoachMode.general => '🤖',
    AICoachMode.checkinAnalysis => '📊',
    AICoachMode.riskDetection => '⚠️',
  };
}

class AICoachService {
  final _db = Supabase.instance.client;

  Future<String> chat(String message, AICoachMode mode) async {
    final res = await _db.functions.invoke('ai-coach', body: {
      'message': message,
      'mode': mode.value,
    });
    if (res.status != 200) throw Exception('AI service unavailable');
    final data = res.data as Map<String, dynamic>;
    return data['reply'] as String? ?? 'No response';
  }

  Future<String> analyzeCheckins(String clientId) async {
    final res = await _db.functions.invoke('ai-coach', body: {
      'message': 'Analyze this client\'s recent check-ins and provide a coaching summary.',
      'mode': AICoachMode.checkinAnalysis.value,
      'target_client_id': clientId,
    });
    if (res.status != 200) throw Exception('AI analysis failed');
    final data = res.data as Map<String, dynamic>;
    return data['reply'] as String? ?? '';
  }

  Future<Map<String, dynamic>> detectRisks(String clientId) async {
    final res = await _db.functions.invoke('ai-coach', body: {
      'message': 'Assess this client for risk factors.',
      'mode': AICoachMode.riskDetection.value,
      'target_client_id': clientId,
    });
    if (res.status != 200) return {'risk_level': 'unknown', 'flags': [], 'recommendation': ''};
    final data = res.data as Map<String, dynamic>;
    final reply = data['reply'] as String? ?? '';
    try {
      final jsonStr = reply.contains('{') ? reply.substring(reply.indexOf('{'), reply.lastIndexOf('}') + 1) : '{}';
      return Map<String, dynamic>.from(Uri.splitQueryString(jsonStr));
    } catch (_) {
      return {'risk_level': 'unknown', 'flags': <String>[], 'recommendation': reply};
    }
  }

  // ── Coaching intelligence layer (ai-coaching-engine) ──────────────────────

  /// Generate a coaching artifact: 'daily_insight' | 'weekly_review' |
  /// 'goal_prediction'. Returns the structured result, or null on failure.
  Future<Map<String, dynamic>?> generate(String type) async {
    try {
      final res = await _db.functions.invoke('ai-coaching-engine', body: {'type': type});
      if (res.status != 200) return null;
      final data = res.data as Map<String, dynamic>;
      return data['result'] as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  /// Today's stored daily insight, if one exists.
  Future<Map<String, dynamic>?> getTodayInsight() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      return await _db.from('ai_insights').select()
          .eq('user_id', uid).eq('type', 'daily_insight').eq('for_date', today)
          .maybeSingle();
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>?> getLatestReview() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      return await _db.from('ai_reviews').select()
          .eq('user_id', uid).order('period_end', ascending: false).limit(1).maybeSingle();
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>?> getLatestPrediction() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      return await _db.from('ai_goal_predictions').select()
          .eq('user_id', uid).order('created_at', ascending: false).limit(1).maybeSingle();
    } catch (_) { return null; }
  }

  Future<List<Map<String, dynamic>>> getConversationHistory({int limit = 20}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final data = await _db
          .from('ai_conversations')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: true)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }
}
