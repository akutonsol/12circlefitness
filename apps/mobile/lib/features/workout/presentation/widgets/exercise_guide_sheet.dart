import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/exercise_guides.dart';
import '../../../exercise_database/data/custom_exercise_service.dart';
import 'youtube_embed.dart';

const _card  = Color(0xFF0E0B16);
const _panel = Color(0xFF171026);
const _brand = Color(0xFFB76DFF);
const _mint  = Color(0xFF6FFBBE);
const _error = Color(0xFFFFB4AB);
const _white = Color(0xFFEDE7F3);
const _muted = Color(0xFFB6A9C4);

/// Tappable from an exercise title — shows form steps, coaching cues, common
/// mistakes, and an in-app video (or a "Watch form video" search) for [name].
void showExerciseGuide(BuildContext context, String name) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ExerciseGuideSheet(name: name),
  );
}

class _ExerciseGuideSheet extends StatelessWidget {
  final String name;
  const _ExerciseGuideSheet({required this.name});

  Future<void> _watchExternal() async {
    final q = Uri.encodeComponent('$name proper form technique');
    final uri = Uri.parse('https://www.youtube.com/results?search_query=$q');
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }

  /// Resolve the best in-app video source: a coach-uploaded clip from the
  /// library (by name), else the curated YouTube id.
  Future<String?> _resolveVideo(ExerciseGuide? guide) async {
    final fromLibrary = await CustomExerciseService().findVideoForName(name);
    return fromLibrary ?? guide?.youtubeId;
  }

  @override
  Widget build(BuildContext context) {
    final guide = guideFor(name);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.menu_book_rounded, color: _brand, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Video (coach-uploaded clip or curated embed, played in-app) ──
          FutureBuilder<String?>(
            future: _resolveVideo(guide),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 64, alignment: Alignment.center,
                  decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
                  child: const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: _brand, strokeWidth: 2)));
              }
              final src = snap.data;
              final player = (src != null) ? buildInAppVideo(src) : null;
              if (player != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(aspectRatio: 16 / 9, child: player),
                );
              }
              return GestureDetector(
                onTap: _watchExternal,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_brand.withValues(alpha: 0.25), _panel],
                      begin: Alignment.centerLeft, end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _brand.withValues(alpha: 0.3))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.play_circle_fill_rounded, color: _brand, size: 26),
                    SizedBox(width: 10),
                    Text('Watch form video',
                      style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 22),

          if (guide == null)
            const Text(
              'Focus on controlled reps with a full range of motion, a braced '
              'core, and a neutral spine. Tap "Watch form video" above for a '
              'demonstration of this movement.',
              style: TextStyle(color: _muted, fontSize: 14, height: 1.5))
          else ...[
            if (guide.steps.isNotEmpty) ...[
              _label('HOW TO', Icons.format_list_numbered_rounded, _brand),
              const SizedBox(height: 8),
              ...guide.steps.asMap().entries.map((e) => _numbered(e.key + 1, e.value)),
              const SizedBox(height: 18),
            ],
            if (guide.cues.isNotEmpty) ...[
              _label('FORM CUES', Icons.lightbulb_outline_rounded, _mint),
              const SizedBox(height: 8),
              ...guide.cues.map((c) => _bullet(c, _mint, Icons.check_circle_outline_rounded)),
              const SizedBox(height: 18),
            ],
            if (guide.mistakes.isNotEmpty) ...[
              _label('COMMON MISTAKES', Icons.warning_amber_rounded, _error),
              const SizedBox(height: 8),
              ...guide.mistakes.map((m) => _bullet(m, _error, Icons.close_rounded)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _label(String text, IconData icon, Color color) => Row(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(width: 6),
    Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
  ]);

  Widget _numbered(int i, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 22, height: 22, alignment: Alignment.center,
        decoration: BoxDecoration(color: _brand.withValues(alpha: 0.18), shape: BoxShape.circle),
        child: Text('$i', style: const TextStyle(color: _brand, fontSize: 11, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: _white, fontSize: 13.5, height: 1.45))),
    ]),
  );

  Widget _bullet(String text, Color color, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: _muted, fontSize: 13.5, height: 1.4))),
    ]),
  );
}
