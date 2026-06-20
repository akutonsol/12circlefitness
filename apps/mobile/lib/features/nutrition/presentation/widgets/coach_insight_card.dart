import 'package:flutter/material.dart';

const _brand    = Color(0xFFA855F7);
const _muted    = Color(0xFFCFC2D6);
const _primary  = Color(0xFFDDB7FF);
const _tertiary = Color(0xFF6FFBBE);

class CoachInsightCard extends StatelessWidget {
  final double protein;
  final double proteinGoal;
  final double calories;
  final double calorieGoal;
  final String coachName;

  const CoachInsightCard({
    super.key,
    required this.protein,
    required this.proteinGoal,
    required this.calories,
    required this.calorieGoal,
    this.coachName = "AI Coach",
  });

  ({String message, IconData icon, Color accent}) _buildInsight() {
    final proteinRemaining = (proteinGoal - protein).clamp(0, proteinGoal);
    final calRemaining = (calorieGoal - calories).clamp(0, calorieGoal);

    if (proteinRemaining <= 0) {
      return (
        message: "Great work — you've hit your protein goal for today. Keep it up!",
        icon: Icons.emoji_events_outlined,
        accent: _tertiary,
      );
    }

    if (proteinRemaining >= 30) {
      return (
        message: "You still need ${proteinRemaining.toInt()}g protein today. "
            "Try adding chicken, Greek yogurt, or a protein shake.",
        icon: Icons.bolt,
        accent: _primary,
      );
    }

    if (proteinRemaining > 0) {
      return (
        message: "Almost there — just ${proteinRemaining.toInt()}g more protein "
            "to hit today's target.",
        icon: Icons.trending_up,
        accent: _brand,
      );
    }

    return (
      message: calRemaining > 0
          ? "${calRemaining.toInt()} kcal remaining today. Stay consistent!"
          : "You're tracking consistently — nice job staying on top of your meals.",
      icon: Icons.insights,
      accent: _primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final insight = _buildInsight();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [insight.accent.withValues(alpha: 0.10), const Color(0xFF0E0B16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insight.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: insight.accent.withValues(alpha: 0.15),
              border: Border.all(color: insight.accent.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Icon(insight.icon, color: insight.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coachName,
                  style: TextStyle(
                    color: insight.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: TextStyle(
                    color: _muted.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
