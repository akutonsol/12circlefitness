import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_nutrition_service.dart';

final aiNutritionServiceProvider = Provider<AiNutritionService>(
  (ref) => AiNutritionService(),
);

class ChatMessage {
  final String content;
  final bool isUser;
  final File? image;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    this.image,
    required this.timestamp,
  });
}

class AiNutritionNotifier extends StateNotifier<List<ChatMessage>> {
  final AiNutritionService _service;

  AiNutritionNotifier(this._service) : super([
    ChatMessage(
      content: 'Hi! I\'m your AI Nutrition Coach. I can help you with meal planning, analyze meal photos, generate grocery lists, and answer any nutrition questions. What would you like help with today?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Build API-ready history from current messages (excludes the pending user turn)
  List<Map<String, dynamic>> _buildHistory() {
    final result = <Map<String, dynamic>>[];
    for (final m in state) {
      final role = m.isUser ? 'user' : 'assistant';
      if (m.isUser && m.image != null) {
        // Image messages can't be replayed as base64 in history efficiently;
        // send a text summary so the conversation context is preserved.
        result.add({'role': role, 'content': '[Photo: ${m.content}]'});
      } else {
        result.add({'role': role, 'content': m.content});
      }
    }
    return result;
  }

  Future<void> sendMessage(String message, {File? image}) async {
    state = [...state, ChatMessage(content: message, isUser: true, image: image, timestamp: DateTime.now())];
    _isLoading = true;

    try {
      final history = _buildHistory();
      // Remove the last entry — it's the message we're about to send
      if (history.isNotEmpty) history.removeLast();

      final response = await _service.sendMessage(
        message: message,
        history: history,
        imageFile: image,
      );

      state = [...state, ChatMessage(content: response, isUser: false, timestamp: DateTime.now())];
    } catch (e) {
      state = [...state, ChatMessage(
        content: 'Sorry, I encountered an error. Please check your API key configuration and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      )];
    } finally {
      _isLoading = false;
    }
  }

  Future<void> analyzePhoto(File imageFile) async {
    await sendMessage('Analyze this meal photo for me.', image: imageFile);
  }

  void clearChat() {
    state = [
      ChatMessage(
        content: 'Hi! I\'m your AI Nutrition Coach. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final aiNutritionNotifierProvider = StateNotifierProvider<AiNutritionNotifier, List<ChatMessage>>(
  (ref) => AiNutritionNotifier(ref.watch(aiNutritionServiceProvider)),
);

class MealPlanNotifier extends StateNotifier<String?> {
  final AiNutritionService _service;
  MealPlanNotifier(this._service) : super(null);

  bool isLoading = false;

  Future<void> generateMealPlan({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required List<String> restrictions,
    required int days,
  }) async {
    isLoading = true;
    try {
      final plan = await _service.generateMealPlan(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        dietaryRestrictions: restrictions,
        days: days,
      );
      state = plan;
    } catch (e) {
      state = 'Error generating meal plan. Please try again.';
    } finally {
      isLoading = false;
    }
  }
}

final mealPlanNotifierProvider = StateNotifierProvider<MealPlanNotifier, String?>(
  (ref) => MealPlanNotifier(ref.watch(aiNutritionServiceProvider)),
);

class GroceryListNotifier extends StateNotifier<String?> {
  final AiNutritionService _service;
  GroceryListNotifier(this._service) : super(null);

  bool isLoading = false;

  Future<void> generateGroceryList(String mealPlan) async {
    isLoading = true;
    try {
      final list = await _service.generateGroceryList(mealPlan: mealPlan);
      state = list;
    } catch (e) {
      state = 'Error generating grocery list. Please try again.';
    } finally {
      isLoading = false;
    }
  }
}

final groceryListNotifierProvider = StateNotifierProvider<GroceryListNotifier, String?>(
  (ref) => GroceryListNotifier(ref.watch(aiNutritionServiceProvider)),
);
