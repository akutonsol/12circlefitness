import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class AiNutritionService {
  final Dio _dio = Dio();
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model  = 'claude-sonnet-4-6';
  static const _system = '''You are an expert AI Nutrition Coach for 12 Circle Fitness,
a premium fitness platform designed for women seeking sustainable body transformation.
Your role is to:
- Analyze meal photos and estimate calories and macros accurately
- Generate personalized meal plans
- Create detailed grocery lists
- Answer nutrition questions with science-backed advice
- Be encouraging, supportive and empowering
- Focus on sustainable, healthy eating habits
Keep responses concise, actionable and motivating.''';

  Options get _options => Options(headers: {
    'Content-Type': 'application/json',
    'anthropic-version': '2023-06-01',
    'x-api-key': AppConstants.claudeApiKey,
  });

  Future<String> sendMessage({
    required String message,
    required List<Map<String, dynamic>> history,
    File? imageFile,
  }) async {
    // Build the user content block — optionally includes an image
    final List<Map<String, dynamic>> userContent = [];
    if (imageFile != null) {
      final bytes  = await imageFile.readAsBytes();
      final b64    = base64Encode(bytes);
      final ext    = imageFile.path.split('.').last.toLowerCase();
      final mime   = ext == 'png' ? 'image/png' : 'image/jpeg';
      userContent.add({
        'type': 'image',
        'source': {'type': 'base64', 'media_type': mime, 'data': b64},
      });
    }
    userContent.add({'type': 'text', 'text': message});

    final messages = [
      ...history,
      {'role': 'user', 'content': userContent},
    ];

    try {
      final response = await _dio.post(
        _apiUrl,
        options: _options,
        data: {
          'model':      _model,
          'max_tokens': 1024,
          'system':     _system,
          'messages':   messages,
        },
      );
      final content = response.data['content'] as List;
      return content.first['text'] as String;
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  Future<String> generateMealPlan({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required List<String> dietaryRestrictions,
    required int days,
  }) async {
    final prompt = '''Generate a $days-day meal plan with the following targets:
- Daily Calories: $calories kcal
- Protein: ${protein}g
- Carbs: ${carbs}g
- Fat: ${fat}g
Dietary restrictions: ${dietaryRestrictions.isEmpty ? 'None' : dietaryRestrictions.join(', ')}

Format each day as:
DAY X:
Breakfast: [meal name] - [calories] kcal | P:[protein]g C:[carbs]g F:[fat]g
Lunch: [meal name] - [calories] kcal | P:[protein]g C:[carbs]g F:[fat]g
Dinner: [meal name] - [calories] kcal | P:[protein]g C:[carbs]g F:[fat]g
Snack: [meal name] - [calories] kcal | P:[protein]g C:[carbs]g F:[fat]g''';

    return sendMessage(message: prompt, history: []);
  }

  Future<String> generateGroceryList({required String mealPlan}) async {
    final prompt = '''Based on this meal plan, generate a comprehensive grocery list organized by category:
$mealPlan

Format as:
PRODUCE:
- item (quantity)

PROTEINS:
- item (quantity)

GRAINS & CARBS:
- item (quantity)

DAIRY & EGGS:
- item (quantity)

PANTRY:
- item (quantity)''';

    return sendMessage(message: prompt, history: []);
  }

  Future<String> analyzeMealPhoto(File imageFile) async {
    return sendMessage(
      message: '''Please analyze this meal photo and provide:
1. Estimated calories
2. Macronutrients (protein, carbs, fat in grams)
3. Main ingredients identified
4. Health assessment (1-10)
5. One suggestion to improve the nutritional balance''',
      history: [],
      imageFile: imageFile,
    );
  }
}
