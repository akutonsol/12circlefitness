import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/exercise_detail_model.dart';
import '../../workout/data/models/video_variant_model.dart';

class CustomExerciseService {
  final _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<List<ExerciseDetail>> getMyExercises() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('custom_exercises')
          .select()
          .eq('coach_id', uid)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => ExerciseDetail.fromJson(r)).toList();
    } catch (_) { return []; }
  }

  /// Tracking flags for an exercise matching [name] in the global library.
  /// Defaults to supporting both when there's no matching record.
  Future<({bool rpe, bool pr})> metaForName(String name) async {
    final n = name.trim();
    if (n.isEmpty) return (rpe: true, pr: true);
    try {
      final rows = await _db
          .from('custom_exercises')
          .select('supports_rpe_tracking, supports_pr_tracking')
          .eq('visibility', 'global')
          .eq('submission_status', 'approved')
          .ilike('name', '%$n%')
          .limit(1);
      if ((rows as List).isNotEmpty) {
        final r = rows.first as Map;
        return (
          rpe: r['supports_rpe_tracking'] != false,
          pr: r['supports_pr_tracking'] != false,
        );
      }
    } catch (_) {}
    return (rpe: true, pr: true);
  }

  /// First video URL for an exercise matching [name] in the global library
  /// (coach/admin uploaded), or null. Used by the in-workout Exercise Guide.
  Future<String?> findVideoForName(String name) async {
    final n = name.trim();
    if (n.isEmpty) return null;
    try {
      final rows = await _db
          .from('custom_exercises')
          .select('name, video_variants')
          .eq('visibility', 'global')
          .eq('submission_status', 'approved')
          .ilike('name', '%$n%')
          .limit(5);
      for (final r in (rows as List)) {
        final vv = r['video_variants'];
        if (vv is List && vv.isNotEmpty && vv.first is Map) {
          final url = (vv.first as Map)['url'] as String?;
          if (url != null && url.trim().isNotEmpty) return url.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<ExerciseDetail>> getGlobalApprovedExercises() async {
    try {
      final rows = await _db
          .from('custom_exercises')
          .select()
          .eq('visibility', 'global')
          .eq('submission_status', 'approved')
          .order('name');
      return (rows as List).map((r) => ExerciseDetail.fromJson(r)).toList();
    } catch (_) { return []; }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<String?> createExercise({
    required String name,
    required String category,
    required String muscleGroup,
    required List<String> secondaryMuscles,
    required String equipment,
    required String difficulty,
    required String description,
    required List<String> instructions,
    required List<String> coachingCues,
    required List<String> commonMistakes,
    required List<String> alternatives,
    String? beginnerModification,
    String? advancedProgression,
    required List<String> tags,
    required List<VideoVariant> videoVariants,
    String? imageUrl,
    String visibility = 'private',
    Map<String, dynamic>? extra, // additional columns (metadata)
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final row = await _db.from('custom_exercises').insert({
        'coach_id': uid,
        'name': name,
        'category': category,
        'muscle_group': muscleGroup,
        'secondary_muscles': secondaryMuscles,
        'equipment': equipment,
        'difficulty': difficulty,
        'description': description,
        'instructions': instructions,
        'coaching_cues': coachingCues,
        'common_mistakes': commonMistakes,
        'alternatives': alternatives,
        if (beginnerModification != null) 'beginner_modification': beginnerModification,
        if (advancedProgression != null) 'advanced_progression': advancedProgression,
        'tags': tags,
        'video_variants': videoVariants.map((v) => v.toJson()).toList(),
        if (imageUrl != null) 'image_url': imageUrl,
        'visibility': visibility,
        ...?extra,
      }).select().single();
      return row['id'] as String;
    } catch (_) { return null; }
  }

  /// Fan a master-schema exercise JSON out into the normalized child tables
  /// (exercise_muscles/equipment/tags/media/substitutions/progressions/
  /// modifications/analytics). Idempotent server-side. Safe to call after
  /// createExercise; failures don't block the core save.
  Future<bool> syncRelations(String exerciseId, Map<String, dynamic> masterJson) async {
    try {
      await _db.rpc('sync_exercise_relations', params: {
        'p_exercise_id': exerciseId,
        'p': masterJson,
      });
      return true;
    } catch (_) { return false; }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<bool> updateExercise(String id, Map<String, dynamic> updates) async {
    try {
      await _db.from('custom_exercises').update(updates).eq('id', id);
      return true;
    } catch (_) { return false; }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteExercise(String id) async {
    try {
      await _db.from('custom_exercises').delete().eq('id', id);
      return true;
    } catch (_) { return false; }
  }

  // ── Submit to Global Library ──────────────────────────────────────────────

  Future<bool> submitForGlobalLibrary(String exerciseId) async {
    try {
      await _db.from('custom_exercises').update({
        'submission_status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
        'visibility': 'team', // visible to coach's clients while pending
      }).eq('id', exerciseId);
      return true;
    } catch (_) { return false; }
  }

  // ── Admin: Global Library moderation (EL-005) ─────────────────────────────

  /// Pending global-library submissions awaiting admin review.
  Future<List<ExerciseDetail>> getPendingGlobalSubmissions() async {
    try {
      final rows = await _db
          .from('custom_exercises')
          .select()
          .eq('submission_status', 'pending')
          .order('submitted_at');
      return (rows as List).map((r) => ExerciseDetail.fromJson(r)).toList();
    } catch (_) { return []; }
  }

  /// Admin approves a submission → it becomes globally visible.
  Future<bool> approveGlobalExercise(String exerciseId) async {
    try {
      await _db.from('custom_exercises').update({
        'submission_status': 'approved',
        'visibility': 'global',
        'approved_by': _uid,
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', exerciseId);
      return true;
    } catch (_) { return false; }
  }

  /// Admin rejects a submission → reverts to the coach's private library.
  Future<bool> rejectGlobalExercise(String exerciseId) async {
    try {
      await _db.from('custom_exercises').update({
        'submission_status': 'rejected',
        'visibility': 'private',
      }).eq('id', exerciseId);
      return true;
    } catch (_) { return false; }
  }

  // ── Image / Video Upload ──────────────────────────────────────────────────

  Future<String?> uploadImage(File file, String exerciseId) async {
    try {
      final ext = file.path.split('.').last;
      final path = 'exercises/$exerciseId/image.$ext';
      await _db.storage.from('exercise-media').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _db.storage.from('exercise-media').getPublicUrl(path);
    } catch (_) { return null; }
  }

  Future<String?> uploadVideo(File file, String exerciseId, String label) async {
    try {
      final ext = file.path.split('.').last;
      final slug = label.toLowerCase().replaceAll(' ', '_');
      final path = 'exercises/$exerciseId/video_$slug.$ext';
      await _db.storage.from('exercise-media').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _db.storage.from('exercise-media').getPublicUrl(path);
    } catch (_) { return null; }
  }
}
