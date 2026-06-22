import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/auth_provider.dart';

enum CoachingMode {
  selfGuided,
  aiGuided,
  coachGuided;

  String get dbValue => switch (this) {
    CoachingMode.selfGuided  => 'self_guided',
    CoachingMode.aiGuided    => 'ai_guided',
    CoachingMode.coachGuided => 'coach_guided',
  };

  String get displayName => switch (this) {
    CoachingMode.selfGuided  => 'Self Guided',
    CoachingMode.aiGuided    => 'AI Guided',
    CoachingMode.coachGuided => 'Coach Guided',
  };

  String get description => switch (this) {
    CoachingMode.selfGuided  =>
        'Structured workouts, nutrition tracking, and habits without a coach.',
    CoachingMode.aiGuided    =>
        'AI-powered plans, progress reviews, and accountability reminders.',
    CoachingMode.coachGuided =>
        'A real human coach manages your programming and keeps you accountable.',
  };

  static CoachingMode fromDb(String? value) => switch (value) {
    'ai_guided'     => CoachingMode.aiGuided,
    'coach_guided'  => CoachingMode.coachGuided,
    _               => CoachingMode.selfGuided,
  };
}

// Mutable notifier — allows mode switching from settings
class CoachingModeNotifier extends StateNotifier<AsyncValue<CoachingMode>> {
  CoachingModeNotifier(this._userId) : super(const AsyncValue.loading()) {
    _load();
  }

  final String _userId;

  Future<void> _load() async {
    if (_userId.isEmpty) {
      state = const AsyncValue.data(CoachingMode.selfGuided);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('user_profiles')
          .select('coaching_mode')
          .eq('id', _userId)
          .maybeSingle();
      state = AsyncValue.data(
          CoachingMode.fromDb(data?['coaching_mode'] as String?));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Persists the coaching mode. Throws on failure (including a 0-row write,
  /// which means RLS/id mismatch silently dropped the update) so the caller can
  /// surface it instead of the change quietly reverting on next load.
  Future<void> setMode(CoachingMode mode) async {
    if (_userId.isEmpty) return;
    final prev = state;
    state = AsyncValue.data(mode); // optimistic update
    try {
      final rows = await Supabase.instance.client
          .from('user_profiles')
          .update({'coaching_mode': mode.dbValue})
          .eq('id', _userId)
          .select('id'); // returns the rows actually updated
      if ((rows as List).isEmpty) {
        throw StateError('coaching_mode update matched no row');
      }
    } catch (e) {
      state = prev; // rollback so UI reflects reality
      rethrow;
    }
    // Mode write succeeded — keep the generated plan in sync. This is secondary,
    // so a failure here must NOT roll back the (already saved) mode change.
    try {
      if (mode == CoachingMode.coachGuided) {
        await Supabase.instance.client.rpc('deactivate_self_generated_plan');
      } else {
        await Supabase.instance.client.rpc('generate_client_plan');
      }
    } catch (_) {/* plan sync is best-effort */}
  }
}

final coachingModeNotifierProvider = StateNotifierProvider<
    CoachingModeNotifier, AsyncValue<CoachingMode>>((ref) {
  final user = ref.watch(currentUserProvider);
  return CoachingModeNotifier(user?.id ?? '');
});

// Convenience read-only provider — defaults to selfGuided while loading
final coachingModeProvider = Provider<CoachingMode>((ref) =>
    ref.watch(coachingModeNotifierProvider).valueOrNull ??
    CoachingMode.selfGuided);
