// Unit tests for 12 Circle Score calculation logic (UC12 / ScoreService math).
// These tests replicate the formulas from score_service.dart without requiring
// Supabase or a Flutter test harness — pure Dart.
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Constants (mirrors ScoreService static consts) ────────────────────────
  const int maxWorkout   = 30;
  const int maxNutrition = 30;
  const int maxHabits    = 20;
  const int maxCheckin   = 10;
  const int maxCommunity = 10;

  // ── Helpers (replicate the inline math in ScoreService methods) ──────────
  int calcNutritionPts(double completionPct) =>
      (maxNutrition * completionPct).round().clamp(0, maxNutrition);

  int calcHabitPts(int completed, int total) {
    if (total == 0) return 0;
    return ((completed / total) * maxHabits).round().clamp(0, maxHabits);
  }

  int totalScore({
    int workout = 0, int nutrition = 0, int habits = 0,
    int checkin = 0, int community = 0,
  }) => workout + nutrition + habits + checkin + community;

  // ── Tests ─────────────────────────────────────────────────────────────────
  group('ScoreService constants', () {
    test('all max values sum to 100', () {
      expect(maxWorkout + maxNutrition + maxHabits + maxCheckin + maxCommunity, 100);
    });

    test('maxWorkout is 30', () => expect(maxWorkout, 30));
    test('maxNutrition is 30', () => expect(maxNutrition, 30));
    test('maxHabits is 20', () => expect(maxHabits, 20));
    test('maxCheckin is 10', () => expect(maxCheckin, 10));
    test('maxCommunity is 10', () => expect(maxCommunity, 10));
  });

  group('addNutritionPoints math', () {
    test('0% completion → 0 pts', () => expect(calcNutritionPts(0.0), 0));
    test('25% completion → 8 pts (7.5 rounds up)', () => expect(calcNutritionPts(0.25), 8));
    test('50% completion → 15 pts', () => expect(calcNutritionPts(0.5), 15));
    test('75% completion → 23 pts (22.5 rounds up)', () => expect(calcNutritionPts(0.75), 23));
    test('100% completion → 30 pts', () => expect(calcNutritionPts(1.0), 30));
    test('110% clamped to 30 pts', () => expect(calcNutritionPts(1.1), 30));
    test('negative clamped to 0 pts', () => expect(calcNutritionPts(-0.5), 0));
  });

  group('addHabitPoints math', () {
    test('0 total habits (guard) → 0 pts', () => expect(calcHabitPts(0, 0), 0));
    test('0/5 habits → 0 pts', () => expect(calcHabitPts(0, 5), 0));
    test('1/5 habits → 4 pts', () => expect(calcHabitPts(1, 5), 4));
    test('3/5 habits → 12 pts', () => expect(calcHabitPts(3, 5), 12));
    test('5/5 habits → 20 pts', () => expect(calcHabitPts(5, 5), 20));
    test('1/3 habits → 7 pts (6.67 rounds up)', () => expect(calcHabitPts(1, 3), 7));
    test('1/1 habit → 20 pts (full)', () => expect(calcHabitPts(1, 1), 20));
  });

  group('totalScore', () {
    test('all zeros → 0', () => expect(totalScore(), 0));

    test('perfect day → 100', () => expect(totalScore(
      workout: 30, nutrition: 30, habits: 20, checkin: 10, community: 10), 100));

    test('partial score sums correctly', () => expect(totalScore(
      workout: 30, nutrition: 15, habits: 12, checkin: 0, community: 0), 57));

    test('cannot exceed 100 with valid inputs', () {
      final score = totalScore(
        workout:   maxWorkout,
        nutrition: maxNutrition,
        habits:    maxHabits,
        checkin:   maxCheckin,
        community: maxCommunity,
      );
      expect(score, lessThanOrEqualTo(100));
    });
  });

  group('month score percentage (activity screen logic)', () {
    double calcMonthPct(int totalPoints, int daysInMonth) {
      if (daysInMonth == 0) return 0;
      return (totalPoints / (daysInMonth * 100) * 100).clamp(0.0, 100.0);
    }

    test('0 points → 0%', () => expect(calcMonthPct(0, 30), 0.0));
    test('perfect month (30 days × 100 pts) → 100%',
        () => expect(calcMonthPct(3000, 30), 100.0));
    test('half score → 50%',
        () => expect(calcMonthPct(1500, 30), closeTo(50.0, 0.01)));
    test('over-cap → clamped to 100%',
        () => expect(calcMonthPct(9999, 30), 100.0));
    test('0 days (guard) → 0%', () => expect(calcMonthPct(0, 0), 0.0));
    test('100 pts in a 31-day month ≈ 3.2%',
        () => expect(calcMonthPct(100, 31), closeTo(3.226, 0.01)));
  });
}
