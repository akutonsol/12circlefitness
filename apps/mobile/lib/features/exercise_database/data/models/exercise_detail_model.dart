import '../../../workout/data/models/video_variant_model.dart';

class ExerciseDetail {
  final String id;
  final String name;
  final String category;
  final String muscleGroup;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final String description;
  final String? videoUrl;
  final List<VideoVariant> videoVariants;
  final String? imageUrl;
  final String? imageAssetPath;
  final List<String> instructions;
  final List<String> coachingCues;
  final List<String> commonMistakes;
  final List<String> alternatives;
  final String? beginnerModification;
  final String? advancedProgression;
  final List<String> tags;
  // 'private' | 'team' | 'global'
  final String visibility;
  // null | 'pending' | 'approved' | 'rejected'
  final String? submissionStatus;
  final String? coachId;

  ExerciseDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.description,
    this.videoUrl,
    List<VideoVariant>? videoVariants,
    this.imageUrl,
    this.imageAssetPath,
    required this.instructions,
    required this.coachingCues,
    required this.commonMistakes,
    required this.alternatives,
    this.beginnerModification,
    this.advancedProgression,
    required this.tags,
    this.visibility = 'global',
    this.submissionStatus,
    this.coachId,
  }) : videoVariants = videoVariants ?? (videoUrl != null ? [VideoVariant(url: videoUrl, label: 'Tutorial', type: VideoVariant.detectType(videoUrl))] : []);

  factory ExerciseDetail.fromJson(Map<String, dynamic> j) {
    final rawVariants = j['video_variants'];
    final variants = (rawVariants is List)
        ? rawVariants.map((v) => VideoVariant.fromJson(v as Map<String, dynamic>)).toList()
        : <VideoVariant>[];
    final legacyUrl = j['video_url'] as String?;
    final allVariants = variants.isNotEmpty
        ? variants
        : (legacyUrl != null ? [VideoVariant(url: legacyUrl, label: 'Tutorial', type: VideoVariant.detectType(legacyUrl))] : <VideoVariant>[]);

    return ExerciseDetail(
      id:                   j['id'] as String,
      name:                 j['name'] as String,
      category:             j['category'] as String? ?? 'Strength',
      muscleGroup:          j['muscle_group'] as String? ?? '',
      secondaryMuscles:     List<String>.from(j['secondary_muscles'] as List? ?? []),
      equipment:            j['equipment'] as String? ?? '',
      difficulty:           j['difficulty'] as String? ?? 'Intermediate',
      description:          j['description'] as String? ?? '',
      videoUrl:             legacyUrl,
      videoVariants:        allVariants,
      imageUrl:             j['image_url'] as String?,
      instructions:         List<String>.from(j['instructions'] as List? ?? []),
      coachingCues:         List<String>.from(j['coaching_cues'] as List? ?? []),
      commonMistakes:       List<String>.from(j['common_mistakes'] as List? ?? []),
      alternatives:         List<String>.from(j['alternatives'] as List? ?? []),
      beginnerModification: j['beginner_modification'] as String?,
      advancedProgression:  j['advanced_progression'] as String?,
      tags:                 List<String>.from(j['tags'] as List? ?? []),
      visibility:           j['visibility'] as String? ?? 'global',
      submissionStatus:     j['submission_status'] as String?,
      coachId:              j['coach_id'] as String?,
    );
  }
}
