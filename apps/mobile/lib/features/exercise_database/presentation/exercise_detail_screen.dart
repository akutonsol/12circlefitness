import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/exercise_database_provider.dart';
import '../data/models/exercise_detail_model.dart';
import '../../workout/data/models/video_variant_model.dart';

class _C {
  static const bg                   = Color(0xFF0E0E0F);
  static const surfaceContainerHigh = Color(0xFF2A2A2B);
  static const primary              = Color(0xFFDDB7FF);
  static const inversePrimary       = Color(0xFF842BD2);
  static const onSurface            = Color(0xFFE5E2E3);
  static const onSurfaceVar         = Color(0xFFCDC3D0);
  static const outline              = Color(0xFF968E99);
  static const outlineVar           = Color(0xFF4B444F);
  static const tertiary             = Color(0xFF6FFBBE);
  static const error                = Color(0xFFFFB4AB);
  static const warning              = Color(0xFFF59E0B);
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(selectedExerciseDetailProvider);
    if (exercise == null) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fitness_center, color: _C.primary, size: 48),
            const SizedBox(height: 16),
            const Text('No exercise selected',
              style: TextStyle(color: _C.onSurface, fontSize: 16)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/train'),
              child: const Text('Back to Library',
                style: TextStyle(color: _C.primary))),
          ]),
        ),
      );
    }
    return _ExerciseDetailView(exercise: exercise);
  }
}

class _ExerciseDetailView extends StatelessWidget {
  final ExerciseDetail exercise;
  const _ExerciseDetailView({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(exercise.difficulty);

    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(slivers: [

        // ── Hero App Bar ──────────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: Colors.transparent,
          expandedHeight: 300,
          pinned: true,
          leading: GestureDetector(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go('/exercise-library'),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18))),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              _heroImage(exercise),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xCC0E0E0F), Color(0xFF0E0E0F)],
                    stops: [0.3, 0.75, 1.0],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              Positioned(
                bottom: 20, left: 20,
                child: Row(children: [
                  _Tag(label: exercise.muscleGroup.toUpperCase()),
                  const SizedBox(width: 8),
                  _Tag(label: exercise.difficulty.toUpperCase(), color: levelColor),
                  const SizedBox(width: 8),
                  _Tag(label: exercise.equipment),
                ])),
            ])),
        ),

        // ── Content ───────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Name + description
              Text(exercise.name,
                style: const TextStyle(color: _C.onSurface, fontSize: 28,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(exercise.description,
                style: const TextStyle(color: _C.onSurfaceVar, fontSize: 14, height: 1.5)),
              const SizedBox(height: 20),

              // Stats chips
              Row(children: [
                Expanded(child: _StatChip(icon: Icons.sports_gymnastics_outlined,
                  label: 'EQUIPMENT', value: exercise.equipment)),
                const SizedBox(width: 10),
                Expanded(child: _StatChip(icon: Icons.signal_cellular_alt_outlined,
                  label: 'DIFFICULTY', value: exercise.difficulty)),
                const SizedBox(width: 10),
                Expanded(child: _StatChip(icon: Icons.adjust_outlined,
                  label: 'MUSCLE', value: exercise.muscleGroup)),
              ]),
              const SizedBox(height: 24),

              // Tags
              if (exercise.tags.isNotEmpty) ...[
                Wrap(spacing: 6, runSpacing: 6,
                  children: exercise.tags.map((t) => _TagChip(label: t)).toList()),
                const SizedBox(height: 24),
              ],

              // Video variants (multi-video with label chips)
              if (exercise.videoVariants.isNotEmpty) ...[
                const _SectionTitle(title: 'Video Tutorials',
                  icon: Icons.play_circle_outline_rounded, iconColor: _C.primary),
                const SizedBox(height: 12),
                ...exercise.videoVariants.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VideoVariantCard(variant: v))),
                const SizedBox(height: 14),
              ] else if (exercise.videoUrl != null) ...[
                _VideoVariantCard(variant: VideoVariant(
                  url: exercise.videoUrl!,
                  label: 'Tutorial',
                  type: VideoVariant.detectType(exercise.videoUrl!))),
                const SizedBox(height: 24),
              ],

              // Secondary muscles
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                const _SectionTitle(title: 'Secondary Muscles'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8,
                  children: exercise.secondaryMuscles
                      .map((m) => _MuscleChip(label: m)).toList()),
                const SizedBox(height: 24),
              ],

              // Instructions
              const _SectionTitle(title: 'Instructions',
                icon: Icons.list_outlined, iconColor: _C.primary),
              const SizedBox(height: 12),
              ..._numberedList(exercise.instructions, _C.primary),
              const SizedBox(height: 24),

              // Coaching cues
              if (exercise.coachingCues.isNotEmpty) ...[
                const _SectionTitle(title: 'Coaching Cues',
                  icon: Icons.tips_and_updates_outlined, iconColor: _C.warning),
                const SizedBox(height: 12),
                ..._numberedList(exercise.coachingCues, _C.warning),
                const SizedBox(height: 24),
              ],

              // Common mistakes
              if (exercise.commonMistakes.isNotEmpty) ...[
                const _SectionTitle(title: 'Common Mistakes',
                  icon: Icons.warning_amber_outlined, iconColor: _C.error),
                const SizedBox(height: 12),
                ..._numberedList(exercise.commonMistakes, _C.error),
                const SizedBox(height: 24),
              ],

              // Beginner modification
              if (exercise.beginnerModification != null) ...[
                _ModCard(icon: Icons.accessibility_new, title: 'Beginner Modification',
                  color: _C.tertiary, text: exercise.beginnerModification!),
                const SizedBox(height: 12),
              ],

              // Advanced progression
              if (exercise.advancedProgression != null) ...[
                _ModCard(icon: Icons.trending_up, title: 'Advanced Progression',
                  color: _C.primary, text: exercise.advancedProgression!),
                const SizedBox(height: 24),
              ],

              // Alternatives
              if (exercise.alternatives.isNotEmpty) ...[
                const _SectionTitle(title: 'Alternatives'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8,
                  children: exercise.alternatives.map((a) => _AltChip(label: a)).toList()),
              ],
            ]),
          )),
      ]),
    );
  }

  Widget _heroImage(ExerciseDetail ex) {
    if (ex.imageAssetPath != null) {
      return Image.asset(ex.imageAssetPath!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientHero(ex.muscleGroup));
    }
    if (ex.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: ex.imageUrl!, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _gradientHero(ex.muscleGroup),
        placeholder: (_, __) => _gradientHero(ex.muscleGroup));
    }
    return _gradientHero(ex.muscleGroup);
  }

  Color _levelColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return const Color(0xFFADC6FF);
      case 'advanced': return _C.tertiary;
      case 'elite': return _C.primary;
      default: return _C.onSurfaceVar;
    }
  }

  Widget _gradientHero(String muscleGroup) {
    final colors = {
      'Chest': [const Color(0xFF2A1A4E), _C.bg],
      'Back': [const Color(0xFF0B2E1A), _C.bg],
      'Legs': [const Color(0xFF1A2E0B), _C.bg],
      'Core': [const Color(0xFF2E1A0B), _C.bg],
      'Shoulders': [const Color(0xFF0B1A2E), _C.bg],
    };
    final pair = colors[muscleGroup] ?? [const Color(0xFF1A1A2E), _C.bg];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pair, begin: Alignment.topLeft, end: Alignment.bottomRight)));
  }

  List<Widget> _numberedList(List<String> items, Color color) {
    return items.asMap().entries.map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('${e.key + 1}',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Text(e.value,
          style: const TextStyle(color: _C.onSurfaceVar, fontSize: 14, height: 1.5))),
      ]),
    )).toList();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _VideoVariantCard extends StatelessWidget {
  final VideoVariant variant;
  const _VideoVariantCard({required this.variant});

  String _normalizeUrl(String url) {
    // Convert Vimeo embed/player URLs to web URLs
    final vimeoMatch = RegExp(r'vimeo\.com/(?:video/)?(\d+)').firstMatch(url);
    if (vimeoMatch != null) return 'https://vimeo.com/${vimeoMatch.group(1)}';
    return url;
  }

  (IconData, Color, String) get _meta {
    if (variant.isYoutube) return (Icons.smart_display_rounded, const Color(0xFFFF0000), 'YouTube');
    if (variant.isVimeo)   return (Icons.play_circle_fill_rounded, const Color(0xFF1AB7EA), 'Vimeo');
    return (Icons.videocam_rounded, _C.primary, 'Video');
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, platform) = _meta;
    return GestureDetector(
      onTap: () async {
        final url = _normalizeUrl(variant.url);
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0D2E), Color(0xFF0F0B1A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(variant.label.toUpperCase(),
              style: const TextStyle(color: _C.primary, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 3),
            Text('Watch on $platform',
              style: const TextStyle(color: _C.onSurfaceVar, fontSize: 12, height: 1.3)),
          ])),
          const Icon(Icons.open_in_new, color: _C.onSurfaceVar, size: 15),
        ])));
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  const _Tag({required this.label, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? _C.onSurfaceVar;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.4))),
      child: Text(label,
        style: TextStyle(color: c, fontSize: 9,
          fontWeight: FontWeight.w700, letterSpacing: 1)));
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _C.inversePrimary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _C.primary.withValues(alpha: 0.2))),
    child: Text(label,
      style: const TextStyle(color: _C.primary, fontSize: 11,
        fontWeight: FontWeight.w600)));
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: _C.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.outlineVar.withValues(alpha: 0.2))),
    child: Column(children: [
      Icon(icon, color: _C.primary, size: 18),
      const SizedBox(height: 4),
      Text(label,
        style: const TextStyle(color: _C.outline, fontSize: 8,
          fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 2),
      Text(value,
        style: const TextStyle(color: _C.onSurface, fontSize: 11,
          fontWeight: FontWeight.w700),
        textAlign: TextAlign.center),
    ]));
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  const _SectionTitle({required this.title, this.icon, this.iconColor});
  @override
  Widget build(BuildContext context) => Row(children: [
    if (icon != null) ...[
      Icon(icon, color: iconColor, size: 18),
      const SizedBox(width: 8),
    ],
    Text(title, style: const TextStyle(color: _C.onSurface, fontSize: 16,
      fontWeight: FontWeight.w700)),
  ]);
}

class _MuscleChip extends StatelessWidget {
  final String label;
  const _MuscleChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _C.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _C.outlineVar.withValues(alpha: 0.3))),
    child: Text(label, style: const TextStyle(color: _C.onSurfaceVar, fontSize: 12)));
}

class _AltChip extends StatelessWidget {
  final String label;
  const _AltChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: _C.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.outlineVar.withValues(alpha: 0.2))),
    child: Text(label, style: const TextStyle(color: _C.onSurfaceVar, fontSize: 13)));
}

class _ModCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String text;
  const _ModCard({required this.icon, required this.title,
    required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontSize: 12,
          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: _C.onSurfaceVar,
          fontSize: 13, height: 1.5)),
      ])),
    ]));
}
