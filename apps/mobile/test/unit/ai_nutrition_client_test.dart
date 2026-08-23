// AI-001 … AI-004 — the AI nutrition client calls the 12 Circle API.
//
// The Anthropic integration lives behind NestJS now, so what the client must
// get right is: the right URL for the build's environment, the user's Supabase
// bearer token, no AI credential of its own, and sane failure handling.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/core/config/app_env.dart';
import 'package:circle_fitness/features/ai_nutrition/data/ai_nutrition_service.dart';

/// Captures the outgoing request and replies with a canned response.
class _RecordingAdapter implements HttpClientAdapter {
  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  _RecordingAdapter({
    this.statusCode = 200,
    this.body = const {'text': 'Here is your meal plan.'},
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _qaConfig = EnvConfig(
  environment: AppEnvironment.qa,
  supabaseUrl: 'https://qa-ref.supabase.co',
  supabaseAnonKey: 'qa-anon-key',
  stripePublishableKey: 'pk_test_qa',
  apiBaseUrl: 'https://qa-api.12circle.test',
);

AiNutritionService serviceWith(
  _RecordingAdapter adapter, {
  EnvConfig env = _qaConfig,
  String? token = 'supabase-access-token',
}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return AiNutritionService(dio: dio, env: env, accessToken: () => token);
}

void main() {
  // AI-001
  group('AI-001 requests go to the environment API', () {
    test('posts to {API_BASE_URL}/ai/nutrition/message', () async {
      final adapter = _RecordingAdapter();
      await serviceWith(adapter).sendMessage(message: 'hi', history: []);

      expect(adapter.lastRequest!.uri.toString(),
          'https://qa-api.12circle.test/ai/nutrition/message');
      expect(adapter.lastRequest!.method, 'POST');
    });

    test('a dev build targets the dev API instead', () async {
      final adapter = _RecordingAdapter();
      final dev = resolveEnvConfig(appEnv: 'dev');
      await serviceWith(adapter, env: dev)
          .sendMessage(message: 'hi', history: []);

      expect(adapter.lastRequest!.uri.toString(),
          'http://localhost:3000/ai/nutrition/message');
    });

    test('a build with no API base URL fails before sending anything',
        () async {
      final adapter = _RecordingAdapter();
      final unconfigured = resolveEnvConfig(appEnv: 'qa');

      await expectLater(
        serviceWith(adapter, env: unconfigured)
            .sendMessage(message: 'hi', history: []),
        throwsA(isA<AiNutritionException>()),
      );
      expect(adapter.lastRequest, isNull);
    });
  });

  // AI-002
  group('AI-002 authorization', () {
    test('sends the Supabase access token as a bearer token', () async {
      final adapter = _RecordingAdapter();
      await serviceWith(adapter).sendMessage(message: 'hi', history: []);

      expect(adapter.lastRequest!.headers['Authorization'],
          'Bearer supabase-access-token');
    });

    test('never sends an Anthropic credential header', () async {
      final adapter = _RecordingAdapter();
      await serviceWith(adapter).sendMessage(message: 'hi', history: []);

      final headers = adapter.lastRequest!.headers.keys
          .map((k) => k.toLowerCase())
          .toList();
      expect(headers, isNot(contains('x-api-key')));
      expect(headers, isNot(contains('anthropic-version')));
    });

    test('refuses to send when the user has no session', () async {
      final adapter = _RecordingAdapter();

      await expectLater(
        serviceWith(adapter, token: null)
            .sendMessage(message: 'hi', history: []),
        throwsA(isA<AiNutritionException>()),
      );
      await expectLater(
        serviceWith(adapter, token: '').sendMessage(message: 'hi', history: []),
        throwsA(isA<AiNutritionException>()),
      );
      expect(adapter.lastRequest, isNull);
    });
  });

  // AI-003
  group('AI-003 payload preserves the existing feature', () {
    test('carries the message and conversation history', () async {
      final adapter = _RecordingAdapter();
      await serviceWith(adapter).sendMessage(
        message: 'What should I eat post-workout?',
        history: [
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Hello!'},
        ],
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['message'], 'What should I eat post-workout?');
      expect(body['history'], hasLength(2));
      expect(body['history'][1]['role'], 'assistant');
      expect(body.containsKey('image'), isFalse);
    });

    test('meal plan and grocery list prompts still round-trip', () async {
      final adapter = _RecordingAdapter();
      final service = serviceWith(adapter);

      final plan = await service.generateMealPlan(
        calories: 1800,
        protein: 140,
        carbs: 160,
        fat: 60,
        dietaryRestrictions: ['dairy-free'],
        days: 3,
      );
      expect(plan, 'Here is your meal plan.');
      var body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['message'], contains('3-day meal plan'));
      expect(body['message'], contains('dairy-free'));

      await service.generateGroceryList(mealPlan: 'DAY 1: eggs');
      body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['message'], contains('grocery list'));
      expect(body['message'], contains('DAY 1: eggs'));
    });

    test('returns the text field from the API response', () async {
      final adapter = _RecordingAdapter(body: {'text': 'Eat more protein.'});
      final reply =
          await serviceWith(adapter).sendMessage(message: 'hi', history: []);
      expect(reply, 'Eat more protein.');
    });
  });

  // AI-004
  group('AI-004 failures surface as actionable messages', () {
    test('401 asks the user to sign in again', () async {
      final adapter = _RecordingAdapter(statusCode: 401, body: {});
      await expectLater(
        serviceWith(adapter).sendMessage(message: 'hi', history: []),
        throwsA(isA<AiNutritionException>().having(
            (e) => e.message, 'message', contains('sign in again'))),
      );
    });

    test('503 reports a temporary outage', () async {
      final adapter = _RecordingAdapter(statusCode: 503, body: {});
      await expectLater(
        serviceWith(adapter).sendMessage(message: 'hi', history: []),
        throwsA(isA<AiNutritionException>().having(
            (e) => e.message, 'message', contains('temporarily unavailable'))),
      );
    });

    test('an empty reply is treated as a failure, not an empty chat bubble',
        () async {
      final adapter = _RecordingAdapter(body: {'text': ''});
      await expectLater(
        serviceWith(adapter).sendMessage(message: 'hi', history: []),
        throwsA(isA<AiNutritionException>()),
      );
    });

    test('no failure message leaks a credential', () async {
      for (final status in [401, 403, 429, 500, 503]) {
        final adapter = _RecordingAdapter(statusCode: status, body: {});
        try {
          await serviceWith(adapter).sendMessage(message: 'hi', history: []);
          fail('expected a failure for status $status');
        } on AiNutritionException catch (e) {
          expect(e.message, isNot(contains('sk-ant')));
          expect(e.message.toLowerCase(), isNot(contains('api key')));
        }
      }
    });
  });
}
