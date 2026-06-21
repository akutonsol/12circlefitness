import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_background.dart';
import '../../../core/widgets/blood_drop.dart';
import '../domain/cycle_phase.dart';
import '../domain/cycle_provider.dart';

const _card  = Color(0xFF0E0B16);
const _brd   = Color(0xFF1A1020);
const _white = Colors.white;
const _muted = Color(0xFFCFC2D6);
const _brand = Color(0xFFA855F7);

class WomensHealthScreen extends ConsumerWidget {
  const WomensHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(cycleStatusProvider);
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          iconTheme: const IconThemeData(color: _white),
          title: const Text("Women's Health",
              style: TextStyle(color: _white, fontWeight: FontWeight.w700)),
        ),
        body: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _brand)),
          error: (e, _) => Center(child: Text('Could not load.\n$e',
              textAlign: TextAlign.center, style: const TextStyle(color: _muted))),
          data: (status) {
            final guide = phaseGuides[status.phase]!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _phaseHeader(status, guide),
                const SizedBox(height: 16),
                _actionRow(context, ref, status),
                const SizedBox(height: 20),
                if (status.hasData) ...[
                  _RecCard('Training', Icons.fitness_center_rounded, guide.color, guide.training),
                  const SizedBox(height: 12),
                  _RecCard('Recovery', Icons.self_improvement_rounded, guide.color, guide.recovery),
                  const SizedBox(height: 12),
                  _RecCard('Nutrition', Icons.restaurant_rounded, guide.color, guide.nutrition),
                  const SizedBox(height: 20),
                ],
                _RecentSymptoms(),
                const SizedBox(height: 16),
                const Text(
                  'Cycle phases and predictions are estimates for general wellness guidance, '
                  'not medical advice. Cycles vary — consult a professional for health concerns.',
                  style: TextStyle(color: Color(0xFF6B6475), fontSize: 11, height: 1.5)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _phaseHeader(CycleStatus s, PhaseGuide g) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [g.color.withValues(alpha: 0.22), _card]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: g.color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        // Cycle-day ring
        SizedBox(
          width: 84, height: 84,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 84, height: 84,
              child: CircularProgressIndicator(
                value: s.hasData ? (s.cycleDay / s.cycleLength).clamp(0.0, 1.0) : 0,
                strokeWidth: 6, backgroundColor: _brd,
                valueColor: AlwaysStoppedAnimation<Color>(g.color)),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(s.hasData ? 'Day' : '—',
                  style: const TextStyle(color: _muted, fontSize: 10)),
              if (s.hasData)
                Text('${s.cycleDay}',
                    style: const TextStyle(color: _white, fontSize: 24, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (s.phase == CyclePhase.menstrual)
              BloodDrop(size: 18, color: g.color)
            else
              Icon(g.icon, color: g.color, size: 18),
            const SizedBox(width: 6),
            Text(g.label, style: TextStyle(color: g.color, fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 2),
          Text(g.tagline, style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (s.hasData) ...[
            if (s.daysUntilNextPeriod != null)
              Text(s.daysUntilNextPeriod! <= 0
                  ? 'Period expected today'
                  : 'Next period in ${s.daysUntilNextPeriod} day${s.daysUntilNextPeriod == 1 ? '' : 's'}',
                  style: const TextStyle(color: _muted, fontSize: 12)),
            if (s.phase == CyclePhase.ovulation || s.phase == CyclePhase.follicular)
              Padding(padding: const EdgeInsets.only(top: 2),
                child: Text('Fertile window now', style: TextStyle(color: g.color, fontSize: 11, fontWeight: FontWeight.w600))),
          ] else
            const Text('Log your last period to see your phase.',
                style: TextStyle(color: _muted, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _actionRow(BuildContext context, WidgetRef ref, CycleStatus s) {
    return Row(children: [
      Expanded(child: _ActionBtn(
        icon: Icons.water_drop_rounded, label: 'Log period', color: const Color(0xFFFF6B8A),
        onTap: () => _logPeriodSheet(context, ref))),
      const SizedBox(width: 10),
      Expanded(child: _ActionBtn(
        icon: Icons.add_chart_rounded, label: 'Log symptoms', color: _brand,
        onTap: () => _symptomsSheet(context, ref))),
    ]);
  }

  void _logPeriodSheet(BuildContext context, WidgetRef ref) {
    DateTime selected = DateTime.now();
    showModalBottomSheet(
      context: context, backgroundColor: _card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(builder: (sheetCtx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Log your period', style: TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('When did your last period start?', style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: sheetCtx, initialDate: selected,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)), lastDate: DateTime.now());
              if (d != null) setSheet(() => selected = d);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF08050F),
                  borderRadius: BorderRadius.circular(14), border: Border.all(color: _brd)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: _brand, size: 18),
                const SizedBox(width: 12),
                Text('${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: _white, fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _brd),
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              onPressed: () async {
                await ref.read(cycleServiceProvider).endCurrentPeriod(DateTime.now());
                ref.read(cycleRefreshProvider.notifier).state++;
                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              },
              child: const Text('Period ended', style: TextStyle(color: _muted)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                await ref.read(cycleServiceProvider).logPeriod(start: selected);
                ref.read(cycleRefreshProvider.notifier).state++;
                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)))),
          ]),
        ]),
      )),
    );
  }

  void _symptomsSheet(BuildContext context, WidgetRef ref) {
    const options = ['Cramps', 'Headache', 'Bloating', 'Fatigue', 'Mood swings',
      'Tender breasts', 'Cravings', 'Acne', 'Back pain', 'Nausea', 'Insomnia', 'Anxiety'];
    final selected = <String>{};
    int energy = 3, mood = 3;
    showModalBottomSheet(
      context: context, backgroundColor: _card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(builder: (sheetCtx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How are you feeling?', style: TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: options.map((s) {
            final on = selected.contains(s);
            return GestureDetector(
              onTap: () => setSheet(() => on ? selected.remove(s) : selected.add(s)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: on ? _brand.withValues(alpha: 0.2) : const Color(0xFF08050F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? _brand : _brd)),
                child: Text(s, style: TextStyle(color: on ? _white : _muted, fontSize: 13)),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),
          _slider('Energy', energy, (v) => setSheet(() => energy = v)),
          _slider('Mood', mood, (v) => setSheet(() => mood = v)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: _white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(cycleServiceProvider).logSymptoms(
                date: DateTime.now(), symptoms: selected.toList(), energy: energy, mood: mood);
              ref.read(cycleRefreshProvider.notifier).state++;
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            },
            child: const Text('Save check-in', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
        ])),
      )),
    );
  }

  Widget _slider(String label, int value, ValueChanged<int> onChanged) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(children: [
      SizedBox(width: 64, child: Text(label, style: const TextStyle(color: _muted, fontSize: 13))),
      Expanded(child: Slider(
        value: value.toDouble(), min: 1, max: 5, divisions: 4,
        activeColor: _brand, inactiveColor: _brd,
        label: '$value', onChanged: (v) => onChanged(v.round()))),
      Text('$value/5', style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _RecCard extends StatelessWidget {
  final String title; final IconData icon; final Color color; final String body;
  const _RecCard(this.title, this.icon, this.color, this.body);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brd)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w800, letterSpacing: 1)),
      ]),
      const SizedBox(height: 8),
      Text(body, style: const TextStyle(color: _muted, fontSize: 13, height: 1.5)),
    ]),
  );
}

class _RecentSymptoms extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSymptomsProvider).valueOrNull ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _brd)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RECENT CHECK-INS', style: TextStyle(color: _muted, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...recent.take(7).map((r) {
          final syms = (r['symptoms'] as List?)?.cast<String>() ?? [];
          return Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 70, child: Text(r['log_date'] as String? ?? '',
                  style: const TextStyle(color: _muted, fontSize: 12))),
              Expanded(child: Text(syms.isEmpty ? '—' : syms.join(', '),
                  style: const TextStyle(color: _white, fontSize: 12))),
            ]));
        }),
      ]),
    );
  }
}
