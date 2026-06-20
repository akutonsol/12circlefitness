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
      }).select().single();
      return row['id'] as String;
    } catch (_) { return null; }
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
