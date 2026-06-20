import 'package:flutter/material.dart';

enum CyclePhase { menstrual, follicular, ovulation, luteal, unknown }

/// A computed snapshot of where the user is in their cycle today.
class CycleStatus {
  final CyclePhase phase;
  final int cycleDay;        // 1-based day of the current cycle
  final int cycleLength;
  final int periodLength;
  final DateTime? lastPeriodStart;
  final DateTime? nextPeriodStart;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;

  const CycleStatus({
    required this.phase,
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
    this.lastPeriodStart,
    this.nextPeriodStart,
    this.fertileStart,
    this.fertileEnd,
  });

  bool get hasData => phase != CyclePhase.unknown && lastPeriodStart != null;
  int? get daysUntilNextPeriod {
    if (nextPeriodStart == null) return null;
    final d = DateTime.now();
    return DateTime(nextPeriodStart!.year, nextPeriodStart!.month, nextPeriodStart!.day)
        .difference(DateTime(d.year, d.month, d.day)).inDays;
  }
}

/// Derives the cycle phase from the last logged period + averages.
CycleStatus computeCycleStatus({
  DateTime? lastPeriodStart,
  int cycleLength = 28,
  int periodLength = 5,
}) {
  if (lastPeriodStart == null) {
    return CycleStatus(
      phase: CyclePhase.unknown, cycleDay: 0,
      cycleLength: cycleLength, periodLength: periodLength);
  }
  final today = DateTime.now();
  final start = DateTime(lastPeriodStart.year, lastPeriodStart.month, lastPeriodStart.day);
  final daysSince = DateTime(today.year, today.month, today.day).difference(start).inDays;
  final cl = cycleLength.clamp(21, 40);
  final pl = periodLength.clamp(2, 10);
  // Day within the current cycle (modulo handles an un-logged new cycle).
  final dayIndex = daysSince < 0 ? 0 : daysSince % cl;
  final cycleDay = dayIndex + 1;
  final ovulation = cl - 14; // luteal phase is ~14 days

  CyclePhase phase;
  if (cycleDay <= pl) {
    phase = CyclePhase.menstrual;
  } else if (cycleDay < ovulation - 1) {
    phase = CyclePhase.follicular;
  } else if (cycleDay <= ovulation + 1) {
    phase = CyclePhase.ovulation;
  } else {
    phase = CyclePhase.luteal;
  }

  // Predicted next period = the start of the cycle we're currently in + cycle length.
  final currentCycleStart = start.add(Duration(days: (daysSince ~/ cl) * cl));
  final nextStart = currentCycleStart.add(Duration(days: cl));
  final fertileStart = currentCycleStart.add(Duration(days: ovulation - 3));
  final fertileEnd = currentCycleStart.add(Duration(days: ovulation + 1));

  return CycleStatus(
    phase: phase, cycleDay: cycleDay, cycleLength: cl, periodLength: pl,
    lastPeriodStart: start, nextPeriodStart: nextStart,
    fertileStart: fertileStart, fertileEnd: fertileEnd,
  );
}

/// Static, evidence-informed guidance per phase (not medical advice).
class PhaseGuide {
  final String label;
  final String tagline;
  final Color color;
  final IconData icon;
  final String training;
  final String recovery;
  final String nutrition;
  const PhaseGuide({
    required this.label, required this.tagline, required this.color, required this.icon,
    required this.training, required this.recovery, required this.nutrition,
  });
}

const _menstrual = Color(0xFFFF6B8A);
const _follicular = Color(0xFF6FFBBE);
const _ovulation = Color(0xFFFFD479);
const _luteal = Color(0xFFB48CFF);

const Map<CyclePhase, PhaseGuide> phaseGuides = {
  CyclePhase.menstrual: PhaseGuide(
    label: 'Menstrual', tagline: 'Rest & restore', color: _menstrual, icon: Icons.water_drop_rounded,
    training: 'Keep intensity low. Gentle movement — walking, mobility, light yoga or easy steady cardio. '
        'Skip max-effort lifts or PR attempts; honour low-energy days.',
    recovery: 'Prioritise sleep and stress reduction. Extra rest is productive now. '
        'Warm baths, stretching and breathwork help with cramps.',
    nutrition: 'Replenish iron (lean red meat, leafy greens, lentils) to offset blood loss. '
        'Stay well hydrated and add magnesium-rich foods (dark chocolate, nuts) for cramps.',
  ),
  CyclePhase.follicular: PhaseGuide(
    label: 'Follicular', tagline: 'Build & push', color: _follicular, icon: Icons.trending_up_rounded,
    training: 'Energy is rising — a great window for strength and higher-intensity work. '
        'Progressively overload, add volume, and tackle harder sessions.',
    recovery: 'Recovery capacity is good. Normal rest days are enough; you can handle a fuller training load.',
    nutrition: 'Fuel the extra output with complex carbs and quality protein. '
        'Estrogen supports carb tolerance — lean into whole-food carbs around training.',
  ),
  CyclePhase.ovulation: PhaseGuide(
    label: 'Ovulation', tagline: 'Peak power', color: _ovulation, icon: Icons.bolt_rounded,
    training: 'Peak strength and power — ideal for PRs and intense sessions. '
        'Warm up thoroughly: joint laxity is higher, so be mindful of form on heavy or explosive lifts.',
    recovery: 'You recover quickly now, but don\'t skip mobility — protect ligaments and joints.',
    nutrition: 'Support performance with lean protein and antioxidant-rich produce (berries, leafy greens). '
        'Add anti-inflammatory fats (olive oil, salmon).',
  ),
  CyclePhase.luteal: PhaseGuide(
    label: 'Luteal', tagline: 'Steady & recover', color: _luteal, icon: Icons.nightlight_round,
    training: 'Energy tapers as the phase progresses. Favour moderate intensity and technique work; '
        'reduce volume in the late luteal days if you feel run down.',
    recovery: 'Body temperature and fatigue rise — add recovery, prioritise sleep, and manage stress.',
    nutrition: 'Metabolism is slightly higher, so cravings are normal. Lean on complex carbs, fibre and '
        'magnesium to ease PMS; limit caffeine, salt and refined sugar to reduce bloating.',
  ),
  CyclePhase.unknown: PhaseGuide(
    label: 'Not tracking', tagline: 'Log a period to begin', color: Color(0xFF888898), icon: Icons.help_outline_rounded,
    training: 'Log your most recent period start date to get cycle-aware training guidance.',
    recovery: 'Once tracking, you\'ll see recovery tips tailored to each phase.',
    nutrition: 'Once tracking, you\'ll see nutrition guidance for each phase of your cycle.',
  ),
};
