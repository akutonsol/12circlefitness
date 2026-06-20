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
