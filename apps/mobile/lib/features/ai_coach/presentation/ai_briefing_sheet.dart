import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/ai_insights.dart';

const _card  = Color(0xFF0E0B16);
const _panel = Color(0xFF171026);
const _mint  = Color(0xFF6FFBBE);
const _brand = Color(0xFFB76DFF);
const _white = Color(0xFFEDE7F3);
const _muted = Color(0xFFB6A9C4);

/// AI-Guided daily briefing: generated daily suggestions, the weekly review,
/// and a progress insight — the verifiable surface for CM-003.
void showAiBriefingSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AiBriefingSheet(),
  );
}

class _AiBriefingSheet extends ConsumerWidget {
  const _AiBriefingSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(aiDailySuggestionsProvider);
    final review      = ref.watch(aiWeeklyReviewProvider);
    final insight     = ref.watch(aiProgressInsightProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
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
            const Icon(Icons.auto_awesome, color: _mint, size: 22),
            const SizedBox(width: 8),
            const Text('Your AI Briefing',
              style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          const Text('Generated from your activity this week.',
            style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 20),

          // ── Progress insight ──
          _sectionLabel('PROGRESS INSIGHT', Icons.insights_rounded),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_mint.withValues(alpha: 0.10), _brand.withValues(alpha: 0.08)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _mint.withValues(alpha: 0.2))),
            child: Text(insight,
              style: const TextStyle(color: _white, fontSize: 14, height: 1.45)),
          ),
          const SizedBox(height: 22),

          // ── Daily suggestions ──
          _sectionLabel('TODAY\'S SUGGESTIONS', Icons.tips_and_updates_outlined),
          const SizedBox(height: 8),
          ...suggestions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brand.withValues(alpha: 0.16))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _brand.withValues(alpha: 0.15)),
                child: Icon(s.icon, color: _brand, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title,
                  style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(s.body, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.4)),
              ])),
            ]),
          )),
          const SizedBox(height: 12),

          // ── Weekly review ──
          _sectionLabel('WEEKLY REVIEW', Icons.calendar_today_rounded),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _mint.withValues(alpha: 0.16))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(review.headline,
                style: const TextStyle(color: _white, fontSize: 14,
                  fontWeight: FontWeight.w600, height: 1.4)),
              const SizedBox(height: 14),
              Row(children: [
                _stat('${review.workouts}', 'Workouts'),
                _stat('${review.activeDays}', 'Active days'),
                _stat('${review.avgScore}', 'Avg score'),
              ]),
            ]),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand, foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Ask your AI coach', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () { Navigator.pop(context); context.push('/ai-coach'); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) => Row(children: [
    Icon(icon, color: _muted, size: 15),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(color: _muted, fontSize: 11,
      fontWeight: FontWeight.w800, letterSpacing: 1.2)),
  ]);

  Widget _stat(String value, String label) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: _mint, fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
    ]),
  );
}
