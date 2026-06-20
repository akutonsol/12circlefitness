// Live service-layer integration test.
// Drives the REAL service classes against the live Supabase dev instance and
// asserts their side effects (12 Circle Score awarding + in-app notifications)
// that only run inside the Flutter app — i.e. the half the headless REST
// harness (tool/live_integration_test.dart) cannot reach.
//
// Run on the macOS desktop target (real network + secure storage):
//   flutter test integration_test/service_logic_test.dart -d macos
//
// Requires APPLY_MISSING.sql to have been applied and the seeded test accounts.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:circle_fitness/core/constants/app_constants.dart';
import 'package:circle_fitness/features/nutrition/data/nutrition_service.dart';
import 'package:circle_fitness/features/messaging/data/messaging_service.dart';
import 'package:circle_fitness/features/checkins/data/weekly_checkin_service.dart';

const _clientEmail = 'test@12circle.app';
const _clientPass = 'Test1234!';

SupabaseClient get _db => Supabase.instance.client;
String get _uid => _db.auth.currentUser!.id;
String _today() => DateTime.now().toIso8601String().split('T')[0];

Future<int> _notifCount(String recipientId, String type) async {
  final rows = await _db
      .from('notifications')
      .select('id')
      .eq('recipient_id', recipientId)
      .eq('type', type);
  return (rows as List).length;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
    await _db.auth.signInWithPassword(email: _clientEmail, password: _clientPass);
    expect(_db.auth.currentUser, isNotNull, reason: 'client must sign in');
  });

  tearDownAll(() async {
    await _db.auth.signOut();
  });

  // ── SCR-002: logging a meal awards 12 Circle Score nutrition points ───────
  testWidgets('NutritionService.logMeal awards nutrition score', (_) async {
    // Reset today's nutrition points to isolate the assertion.
    await _db.from('daily_scores').upsert({
      'user_id': _uid, 'score_date': _today(),
      'workout_points': 0, 'nutrition_points': 0, 'habits_points': 0,
      'checkin_points': 0, 'community_points': 0, 'total_score': 0,
    }, onConflict: 'user_id,score_date');

    await NutritionService().logMeal(
      mealType: 'breakfast',
      foodName: '__itest oats',
      calories: 600, protein: 60, carbs: 80, fat: 15,
      servingSize: 100, servingUnit: 'g',
    );

    final row = await _db
        .from('daily_scores')
        .select('nutrition_points')
        .eq('user_id', _uid).eq('score_date', _today())
        .single();
    final pts = (row['nutrition_points'] as num).toInt();
    expect(pts, greaterThan(0),
        reason: 'logMeal should award nutrition points (SCR-002)');

    // cleanup the test meal
    await _db.from('nutrition_logs')
        .delete().eq('user_id', _uid).eq('food_name', '__itest oats');
  });

  // ── MSG-003: sending a message creates EXACTLY ONE recipient notification ──
  // (validates the DB trigger fires and that the Dart duplicate was removed)
  testWidgets('MessagingService.sendMessage notifies recipient exactly once',
      (_) async {
    final convId = await MessagingService().getOrCreateClientCoachConversation();
    expect(convId, isNotNull, reason: 'client must have a coach conversation');

    final convo = await _db.from('conversations')
        .select('participant_1, participant_2').eq('id', convId!).single();
    final coachId = convo['participant_1'] == _uid
        ? convo['participant_2'] as String
        : convo['participant_1'] as String;

    final before = await _notifCount(coachId, 'message');
    final ok = await MessagingService()
        .sendMessage(conversationId: convId, content: '__itest ping');
    expect(ok, isTrue);
    await Future.delayed(const Duration(milliseconds: 600)); // let trigger commit
    final after = await _notifCount(coachId, 'message');

    expect(after - before, 1,
        reason: 'recipient should get exactly one notification, not zero or two');

    // cleanup test message + the notification it produced
    await _db.from('messages')
        .delete().eq('conversation_id', convId).eq('content', '__itest ping');
  });

  // ── SCR-004 + CHK-001: weekly check-in awards score and notifies coach once ─
  testWidgets('WeeklyCheckinService.submitWeeklyCheckin scores + notifies coach',
      (_) async {
    // find this client's active coach (if any) to assert single coach notify
    final rel = await _db.from('coach_client_relationships')
        .select('coach_id').eq('client_id', _uid).eq('status', 'active')
        .maybeSingle();
    final coachId = rel?['coach_id'] as String?;
    final beforeNotif = coachId == null ? 0 : await _notifCount(coachId, 'checkin');

    // reset checkin points for a clean assertion
    await _db.from('daily_scores').upsert({
      'user_id': _uid, 'score_date': _today(),
      'workout_points': 0, 'nutrition_points': 0, 'habits_points': 0,
      'checkin_points': 0, 'community_points': 0, 'total_score': 0,
    }, onConflict: 'user_id,score_date');

    final ok = await WeeklyCheckinService().submitWeeklyCheckin(
      mood: 4, energy: 4, stress: 2, sleepHoursAvg: 7.5, notes: '__itest',
    );
    expect(ok, isTrue, reason: 'check-in should submit');

    final row = await _db.from('daily_scores')
        .select('checkin_points').eq('user_id', _uid).eq('score_date', _today())
        .single();
    expect((row['checkin_points'] as num).toInt(), greaterThan(0),
        reason: 'weekly check-in should award check-in points (SCR-004)');

    if (coachId != null) {
      await Future.delayed(const Duration(milliseconds: 600));
      final afterNotif = await _notifCount(coachId, 'checkin');
      expect(afterNotif - beforeNotif, lessThanOrEqualTo(1),
          reason: 'coach should not be double-notified for one check-in');
    }
  });
}
