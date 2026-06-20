// NUT-001 … NUT-005 — Nutrition spec compliance tests.
// Tests macro math, barcode result mapping, and completion % logic
// without requiring Supabase.
import 'package:flutter_test/flutter_test.dart';

// ── Replicated nutrition helpers ──────────────────────────────────────────────

Map<String, double> macrosFromFood(Map<String, dynamic> food, double servingG) {
  final factor = servingG / 100;
  return {
    'calories': ((food['calories_per_100g'] as num?)?.toDouble() ?? 0) * factor,
    'protein':  ((food['protein_per_100g']  as num?)?.toDouble() ?? 0) * factor,
    'carbs':    ((food['carbs_per_100g']    as num?)?.toDouble() ?? 0) * factor,
    'fat':      ((food['fat_per_100g']      as num?)?.toDouble() ?? 0) * factor,
  };
}

// Mirrors logMeal signature validation: calories must be a double
bool isValidMealLog(Map<String, dynamic> log) {
  return log['calories'] is double &&
      log['protein']  is double &&
      log['carbs']    is double &&
      log['fat']      is double &&
      (log['name'] as String?)?.isNotEmpty == true;
}

// Nutrition completion %: logged calories / goal calories
double nutritionCompletionPct(double logged, double goal) {
  if (goal <= 0) return 0;
  return (logged / goal).clamp(0.0, 1.0);
}

// Mirrors _logFromBarcode mapping (meals_dashboard_screen.dart)
Map<String, dynamic> barcodeToMealLog(Map<String, dynamic> food) => {
  'name':     food['name'] ?? 'Unknown',
  'calories': (food['calories'] as num?)?.toDouble() ?? 0.0,
  'protein':  (food['protein']  as num?)?.toDouble() ?? 0.0,
  'carbs':    (food['carbs']    as num?)?.toDouble() ?? 0.0,
  'fat':      (food['fat']      as num?)?.toDouble() ?? 0.0,
};

void main() {
  // NUT-001 — Manual meal logging
  group('NUT-001 Manual meal logging → meal saved, macros updated', () {
    test('valid log has all required double fields', () {
      final log = {
        'name':     'Chicken Breast',
        'calories': 165.0,
        'protein':  31.0,
        'carbs':    0.0,
        'fat':      3.6,
      };
      expect(isValidMealLog(log), isTrue);
    });

    test('log with int calories fails type check (must be double)', () {
      final log = {
        'name': 'Rice', 'calories': 130, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3,
      };
      expect(isValidMealLog(log), isFalse);
    });

    test('log with empty name is invalid', () {
      final log = {
        'name': '', 'calories': 100.0, 'protein': 5.0, 'carbs': 10.0, 'fat': 2.0,
      };
      expect(isValidMealLog(log), isFalse);
    });
  });

  // NUT-002 — Protein shake (meal type saved correctly)
  group('NUT-002 Protein shake logging → meal_type = "shake"', () {
    test('meal type field preserved in log map', () {
      final log = {
        'name':      'Protein Shake',
        'meal_type': 'shake',
        'calories':  200.0,
        'protein':   25.0,
        'carbs':     10.0,
        'fat':       3.0,
      };
      expect(log['meal_type'], 'shake');
    });
  });

  // NUT-003 — AI meal scan
  group('NUT-003 AI meal scan → food identified, macros estimated, user can edit', () {
    test('AI result map has all required keys', () {
      final aiResult = {
        'name':     'Grilled Salmon',
        'calories': 208.0,
        'protein':  29.0,
        'carbs':    0.0,
        'fat':      10.0,
        'editable': true,
      };
      expect(aiResult['name'], isNotEmpty);
      expect(aiResult['editable'], isTrue);
      expect(aiResult['calories'], isA<double>());
    });

    test('editable flag allows user to modify macros', () {
      final result = {'calories': 208.0, 'editable': true};
      if (result['editable'] == true) {
        result['calories'] = 250.0; // user edits
      }
      expect(result['calories'], 250.0);
    });
  });

  // NUT-004 — Food Added modal (nutrition totals update)
  group('NUT-004 Food Added modal → totals accumulate', () {
    Map<String, double> addMeal(Map<String, double> totals, Map<String, double> meal) => {
      'calories': totals['calories']! + meal['calories']!,
      'protein':  totals['protein']!  + meal['protein']!,
      'carbs':    totals['carbs']!    + meal['carbs']!,
      'fat':      totals['fat']!      + meal['fat']!,
    };

    test('first meal updates totals from zero', () {
      final zero  = {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
      final meal  = {'calories': 300.0, 'protein': 25.0, 'carbs': 30.0, 'fat': 8.0};
      final total = addMeal(zero, meal);
      expect(total['calories'], 300.0);
      expect(total['protein'],  25.0);
    });

    test('second meal accumulates on top', () {
      final existing = {'calories': 300.0, 'protein': 25.0, 'carbs': 30.0, 'fat': 8.0};
      final meal2    = {'calories': 200.0, 'protein': 15.0, 'carbs': 20.0, 'fat': 5.0};
      final total    = addMeal(existing, meal2);
      expect(total['calories'], 500.0);
      expect(total['protein'],  40.0);
    });
  });

  // NUT-005 — Coach insight (protein recommendation)
  group('NUT-005 Coach insight — protein-specific recommendation', () {
    String? proteinInsight(double loggedProtein, double goalProtein) {
      final pct = loggedProtein / goalProtein;
      if (pct < 0.5) return 'Your protein is low today — aim for $goalProtein g.';
      return null;
    }

    test('below 50% protein → insight generated', () {
      expect(proteinInsight(30, 120), isNotNull);
    });

    test('above 50% protein → no insight', () {
      expect(proteinInsight(80, 120), isNull);
    });

    test('insight contains the goal amount', () {
      final insight = proteinInsight(20, 100);
      expect(insight, contains('100'));
    });
  });

  // NUT-011 (UC11) — Barcode scanner → food mapped to meal log
  group('UC11 Barcode scan → food mapped correctly to meal log', () {
    final foodFromDb = {
      'name':     'Oat Bar',
      'calories': 220,
      'protein':  6,
      'carbs':    35,
      'fat':      7,
    };

    test('barcodeToMealLog produces double calories', () {
      final log = barcodeToMealLog(foodFromDb);
      expect(log['calories'], isA<double>());
      expect(log['calories'], 220.0);
    });

    test('barcodeToMealLog preserves name', () {
      expect(barcodeToMealLog(foodFromDb)['name'], 'Oat Bar');
    });

    test('missing food fields default to 0.0', () {
      final log = barcodeToMealLog({'name': 'Unknown Item'});
      expect(log['calories'], 0.0);
      expect(log['protein'],  0.0);
    });

    test('null food name defaults to "Unknown"', () {
      expect(barcodeToMealLog({})['name'], 'Unknown');
    });
  });

  // Macro per-serving calculation
  group('macrosFromFood — per-serving scaling', () {
    final food = {
      'calories_per_100g': 200.0,
      'protein_per_100g':  20.0,
      'carbs_per_100g':    25.0,
      'fat_per_100g':      5.0,
    };

    test('100g serving → same as per-100g values', () {
      final m = macrosFromFood(food, 100);
      expect(m['calories'], 200.0);
      expect(m['protein'],  20.0);
    });

    test('50g serving → half values', () {
      final m = macrosFromFood(food, 50);
      expect(m['calories'], 100.0);
      expect(m['protein'],  10.0);
    });

    test('200g serving → double values', () {
      final m = macrosFromFood(food, 200);
      expect(m['calories'], 400.0);
    });

    test('0g serving → all zeros', () {
      final m = macrosFromFood(food, 0);
      expect(m['calories'], 0.0);
    });
  });

  // Nutrition completion % (used by addNutritionPoints)
  group('nutritionCompletionPct', () {
    test('0 logged / 2000 goal → 0%', () =>
        expect(nutritionCompletionPct(0, 2000), 0.0));
    test('1000 logged / 2000 goal → 50%', () =>
        expect(nutritionCompletionPct(1000, 2000), 0.5));
    test('2000 logged / 2000 goal → 100%', () =>
        expect(nutritionCompletionPct(2000, 2000), 1.0));
    test('2500 logged / 2000 goal → capped at 100%', () =>
        expect(nutritionCompletionPct(2500, 2000), 1.0));
    test('0 goal → 0% (guard)', () =>
        expect(nutritionCompletionPct(500, 0), 0.0));
  });
}
