import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/checkin_model.dart';
import '../../notifications/data/notification_service.dart';
import '../../coach/data/score_service.dart';
import '../../scoring/data/score_engine.dart';

class WeeklyCheckinService {
  final _supabase = Supabase.instance.client;

  ({int weekNumber, DateTime weekStart}) _weekInfo(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final daysSinceJan1 = date.difference(jan1).inDays;
    final weekNumber = ((daysSinceJan1 + jan1.weekday - 1) / 7).floor() + 1;
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    return (
      weekNumber: weekNumber,
      weekStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
    );
  }

  Future<List<WeeklyCheckin>> getWeeklyCheckins({int limit = 10}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final data = await _supabase
          .from('weekly_checkins')
          .select()
          .eq('user_id', userId)
          .order('week_start_date', ascending: false)
          .limit(limit);
      return (data as List)
          .map((row) => _fromRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<WeeklyCheckin> getCurrentWeekCheckin() async {
    final userId = _supabase.auth.currentUser?.id;
    final now = DateTime.now();
    final info = _weekInfo(now);

    if (userId != null) {
      try {
        final data = await _supabase
            .from('weekly_checkins')
            .select()
            .eq('user_id', userId)
            .eq('week_start_date', info.weekStart.toIso8601String().split('T')[0])
            .maybeSingle();
        if (data != null) return _fromRow(data);
      } catch (_) {}
    }

    return WeeklyCheckin(
      id: 'pending-${info.weekStart.toIso8601String()}',
      weekNumber: info.weekNumber,
      weekStartDate: info.weekStart,
      status: CheckinStatus.pending,
      responses: const [],
      overallScore: 0,
    );
  }

  Future<bool> submitWeeklyCheckin({
    required int mood,
    required int energy,
    required int stress,
    required double sleepHoursAvg,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final now = DateTime.now();
    final info = _weekInfo(now);
    final score = _computeScore(
      mood: mood, energy: energy, stress: stress, sleepHoursAvg: sleepHoursAvg);

    try {
      await _supabase.from('weekly_checkins').upsert({
        'user_id': userId,
        'week_number': info.weekNumber,
        'week_start_date': info.weekStart.toIso8601String().split('T')[0],
        'status': 'submitted',
        'mood': mood,
        'energy': energy,
        'stress_level': stress,
        'sleep_hours_avg': sleepHoursAvg,
        'notes': notes ?? '',
        'overall_score': score,
        'submitted_at': now.toIso8601String(),
      }, onConflict: 'user_id,week_start_date');
      // Award 12 Circle Score check-in points (SCR-004) — idempotent.
      await ScoreService().addCheckinPoints();
      await ScoreEngine().weeklyCheckin(info.weekStart.toIso8601String().split('T')[0]);
      // Coach notification (CHK-001) is handled server-side by the
      // trg_notify_coach_on_checkin DB trigger, so no Dart-side insert here.
      return true;
    } catch (e) {
      return false;
    }
  }

  double _computeScore({
    required int mood,
    required int energy,
    required int stress,
    required double sleepHoursAvg,
  }) {
    final moodScore = (mood / 5) * 10;
    final energyScore = (energy / 5) * 10;
    final stressScore = ((6 - stress) / 5) * 10;
    final sleepScore = (sleepHoursAvg.clamp(0, 9) / 9) * 10;
    final avg = (moodScore + energyScore + stressScore + sleepScore) / 4;
    return double.parse(avg.toStringAsFixed(1));
  }

  /// Coach-side: fetch all clients' submitted weekly checkins awaiting review,
  /// joined with basic client profile info.
  Future<List<Map<String, dynamic>>> getSubmittedCheckinsForCoach() async {
    try {
      final data = await _supabase
          .from('weekly_checkins')
          .select('*, user_profiles!weekly_checkins_user_id_fkey(first_name, last_name, email)')
          .eq('status', 'submitted')
          .order('submitted_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      // Fallback if the FK relationship name differs: fetch without join
      try {
        final data = await _supabase
            .from('weekly_checkins')
            .select()
            .eq('status', 'submitted')
            .order('submitted_at', ascending: true);
        return List<Map<String, dynamic>>.from(data);
      } catch (e2) {
        return [];
      }
    }
  }

  Future<bool> submitCoachFeedback({
    required String checkinId,
    required String message,
    required List<String> recommendations,
    required String coachName,
  }) async {
    try {
      final updated = await _supabase.from('weekly_checkins').update({
        'status': 'reviewed',
        'feedback_message': message,
        'feedback_recommendations': recommendations,
        'coach_name': coachName,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', checkinId).select('user_id').maybeSingle();
      // Notify the client that their coach responded (CHK-003).
      final clientId = updated?['user_id'] as String?;
      if (clientId != null) {
        await NotificationService().notifyUser(
          recipientId: clientId,
          type: 'checkin',
          title: 'Coach Feedback Ready',
          body: '$coachName reviewed your check-in and left feedback.',
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  WeeklyCheckin _fromRow(Map<String, dynamic> row) {
    final statusStr = row['status'] as String? ?? 'pending';
    final status = CheckinStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => CheckinStatus.pending,
    );

    CoachFeedback? feedback;
    if (status == CheckinStatus.reviewed && row['feedback_message'] != null) {
      feedback = CoachFeedback(
        message: row['feedback_message'] as String,
        recommendations: (row['feedback_recommendations'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        reviewedAt: row['reviewed_at'] != null
            ? DateTime.parse(row['reviewed_at'])
            : DateTime.now(),
        coachName: row['coach_name'] as String? ?? 'Coach',
      );
    }

    final responses = <CheckinResponse>[];
    if (row['mood'] != null) {
      responses.add(CheckinResponse(questionId: 'mood', answer: row['mood']));
    }
    if (row['energy'] != null) {
      responses.add(CheckinResponse(questionId: 'energy', answer: row['energy']));
    }
    if (row['stress_level'] != null) {
      responses.add(CheckinResponse(questionId: 'stress_level', answer: row['stress_level']));
    }
    if (row['sleep_hours_avg'] != null) {
      responses.add(CheckinResponse(questionId: 'sleep_hours_avg', answer: row['sleep_hours_avg']));
    }
    if (row['notes'] != null && (row['notes'] as String).isNotEmpty) {
      responses.add(CheckinResponse(questionId: 'notes', answer: row['notes']));
    }

    return WeeklyCheckin(
      id: row['id'] as String,
      weekNumber: row['week_number'] as int,
      weekStartDate: DateTime.parse(row['week_start_date']),
      status: status,
      responses: responses,
      feedback: feedback,
      overallScore: (row['overall_score'] as num?)?.toDouble() ?? 0,
      submittedAt: row['submitted_at'] != null
          ? DateTime.parse(row['submitted_at'])
          : null,
    );
  }
}
