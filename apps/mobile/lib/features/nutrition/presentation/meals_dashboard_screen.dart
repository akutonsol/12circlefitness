import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/nutrition_service.dart';
import '../data/models/food_model.dart';
import '../domain/nutrition_provider.dart' hide nutritionServiceProvider;
import '../../coaching_mode/domain/coaching_mode_provider.dart';
import 'widgets/food_added_dialog.dart';
import 'widgets/ai_scan_view.dart';
import 'widgets/barcode_scan_view.dart';

// ── Colors ─────────────────────────────────────────────────────────────────
const _bg    = Color(0xFF050510);
const _card  = Color(0xFF111120);
const _brand = Color(0xFFA855F7);
const _white = Colors.white;
const _grey  = Color(0xFF888898);
const _blue  = Color(0xFF60A5FA);

// ── Providers ──────────────────────────────────────────────────────────────
final _svcProvider = Provider<NutritionService>((ref) => NutritionService());

final _totalsProvider = FutureProvider<Map<String, double>>(
  (ref) async => ref.watch(_svcProvider).getTodayTotals());

final _logsForDateProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>(
  (ref, date) async => ref.watch(_svcProvider).getLogsForDate(date));

// ── Screen ─────────────────────────────────────────────────────────────────
class MealsDashboardScreen extends ConsumerStatefulWidget {
  const MealsDashboardScreen({super.key});
  @override
  ConsumerState<MealsDashboardScreen> createState() =>
      _MealsDashboardScreenState();
}

class _MealsDashboardScreenState
    extends ConsumerState<MealsDashboardScreen> {
  late DateTime _selectedDate;
  String _mealFilter = 'breakfast';
  int    _water      = 3;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  List<Widget> _innerChildren(
    double cal, double protein, double carbs, double fat,
    double calGoal, double proteinGoal, double carbGoal, double fatGoal,
    AsyncValue<List<Map<String, dynamic>>> logsAsync,
    BuildContext context,
  ) {
    final items = <Widget>[
      _MealTabs(
        active: _mealFilter,
        onSelect: (t) => setState(() => _mealFilter = t)),
      const SizedBox(height: 16),
    ];
    if (_isToday) {
      items.addAll([
        _CalorieCard(cal: cal, protein: protein, carbs: carbs, fat: fat,
          calGoal: calGoal, proteinGoal: proteinGoal, carbGoal: carbGoal, fatGoal: fatGoal),
        const SizedBox(height: 12),
        _CoachCard(protein: protein, cal: cal, proteinGoal: proteinGoal, calGoal: calGoal),
        const SizedBox(height: 12),
        _WaterCard(
          glasses: _water,
          onTap: (i) => setState(() =>
            _water = i + 1 == _water ? i : i + 1)),
        const SizedBox(height: 12),
      ]);
    }
    items.add(logsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: _brand))),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final logs = all
          .where((m) => (m['meal_type'] as String?) == _mealFilter)
          .toList();
        if (logs.isEmpty) {
          return _EmptyMeals(
            mealType: _mealFilter,
            onAdd: () => _showAddSheet(context));
        }
        return Column(
          children: logs.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MealCard(meal: m))).toList());
      }));
    items.add(const SizedBox(height: 16));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(_logsForDateProvider(_selectedDate));
    final totals    = ref.watch(_totalsProvider);
    final goals     = ref.watch(nutritionGoalsProvider);
    final cal     = totals.valueOrNull?['calories'] ?? 0.0;
    final protein = totals.valueOrNull?['protein']  ?? 0.0;
    final carbs   = totals.valueOrNull?['carbs']    ?? 0.0;
    final fat     = totals.valueOrNull?['fat']      ?? 0.0;
    final calGoal     = goals.valueOrNull?['calories'] ?? 2000.0;
    final proteinGoal = goals.valueOrNull?['protein']  ?? 120.0;
    final carbGoal    = goals.valueOrNull?['carbs']    ?? 220.0;
    final fatGoal     = goals.valueOrNull?['fat']      ?? 65.0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onAdd: () => _showAddSheet(context)),
            Expanded(
              child: RefreshIndicator(
                color: _brand,
                backgroundColor: _card,
                onRefresh: () async {
                  ref.invalidate(_totalsProvider);
                  ref.invalidate(_logsForDateProvider(_selectedDate));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateStrip(
                        selected: _selectedDate,
                        onSelect: (d) => setState(() {
                          _selectedDate = d;
                          ref.invalidate(_logsForDateProvider(d));
                        })),
                      // Modality banner
                      Builder(builder: (ctx) {
                        final mode = ref.watch(coachingModeProvider);
                        if (mode == CoachingMode.aiGuided) {
                          return GestureDetector(
                            onTap: () => context.push('/ai-nutrition'),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.25))),
                              child: Row(children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4), size: 14),
                                const SizedBox(width: 8),
                                const Expanded(child: Text(
                                  'AI-Guided — get an AI meal plan & smart suggestions',
                                  style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12))),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF06B6D4), size: 16),
                              ])));
                        }
                        if (mode == CoachingMode.coachGuided) {
                          return Container(
                            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6FFBBE).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF6FFBBE).withValues(alpha: 0.2))),
                            child: const Row(children: [
                              Icon(Icons.person_outline_rounded, color: Color(0xFF6FFBBE), size: 14),
                              SizedBox(width: 8),
                              Expanded(child: Text(
                                'Coach-Guided — your coach can view your nutrition logs',
                                style: TextStyle(color: Color(0xFF6FFBBE), fontSize: 12))),
                            ]));
                        }
                        return const SizedBox.shrink();
                      }),
                      const Divider(
                        height: 1, thickness: 1,
                        color: Color(0xFF1E1E30)),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _innerChildren(
                            cal, protein, carbs, fat,
                            calGoal, proteinGoal, carbGoal, fatGoal,
                            logsAsync, context))),
                    ])))),
          ])));
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMealSheet(onLogged: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          ref.invalidate(_totalsProvider);
          ref.invalidate(_logsForDateProvider(_selectedDate));
          ref.invalidate(todayNutritionProvider);
        }
      }));
  }
}

// ── Header ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    color: _bg,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Row(children: [
      GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/home'),
        child: const Icon(Icons.chevron_left, color: _brand, size: 30)),
      const Expanded(
        child: Text('Nutrition',
          textAlign: TextAlign.center,
          style: TextStyle(color: _white, fontSize: 18,
            fontWeight: FontWeight.w700))),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _brand,
            boxShadow: [BoxShadow(
              color: _brand.withValues(alpha: 0.55),
              blurRadius: 18, spreadRadius: 2)]),
          child: const Icon(Icons.add, color: _white, size: 26))),
    ]));
}

// ── Date strip ─────────────────────────────────────────────────────────────
class _DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _DateStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(5, (i) {
          final raw = DateTime.now().subtract(Duration(days: 2 - i));
          final d   = DateTime(raw.year, raw.month, raw.day);
          final active = d.year == selected.year &&
              d.month == selected.month &&
              d.day == selected.day;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(22)),
                alignment: Alignment.center,
                child: Text(
                  '${months[d.month - 1]} ${d.day}',
                  style: TextStyle(
                    color: active ? _white : _grey,
                    fontSize: 13,
                    fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w400)))));
        })));
  }
}

// ── Meal type tabs ─────────────────────────────────────────────────────────
class _MealTabs extends StatelessWidget {
  final String active;
  final ValueChanged<String> onSelect;
  const _MealTabs({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14)),
    padding: const EdgeInsets.all(4),
    child: Row(children: [
      _MealTab('Breakfast', 'breakfast', active, onSelect),
      _MealTab('Lunch',     'lunch',     active, onSelect,
        leftDivider: active != 'breakfast' && active != 'lunch'),
      _MealTab('Dinner',    'dinner',    active, onSelect,
        leftDivider: active != 'lunch' && active != 'dinner'),
    ]));
}

class _MealTab extends StatelessWidget {
  final String label, value, active;
  final ValueChanged<String> onSelect;
  final bool leftDivider;
  const _MealTab(this.label, this.value, this.active, this.onSelect,
    {this.leftDivider = false});

  @override
  Widget build(BuildContext context) {
    final isActive = value == active;
    return Expanded(
      child: Row(children: [
        if (leftDivider)
          Container(width: 1, height: 20,
            color: _grey.withValues(alpha: 0.35)),
        Expanded(
          child: GestureDetector(
            onTap: () => onSelect(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)])
                  : null,
                borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(label,
                style: TextStyle(
                  color: isActive ? _white : _grey,
                  fontSize: 14,
                  fontWeight: isActive
                    ? FontWeight.w700
                    : FontWeight.w500))))),
      ]));
  }
}

// ── Calorie + macro card ───────────────────────────────────────────────────
class _CalorieCard extends StatelessWidget {
  final double cal, protein, carbs, fat;
  final double calGoal, proteinGoal, carbGoal, fatGoal;
  const _CalorieCard({required this.cal, required this.protein,
    required this.carbs, required this.fat,
    required this.calGoal, required this.proteinGoal,
    required this.carbGoal, required this.fatGoal});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      // Horseshoe ring
      SizedBox(width: 120, height: 120,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: const Size(120, 120),
            painter: _HorseshoeRing(
              progress: calGoal == 0 ? 0 : (cal / calGoal).clamp(0.0, 1.0))),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(cal.toInt().toString(),
              style: const TextStyle(color: _white, fontSize: 28,
                fontWeight: FontWeight.w800, height: 1.0)),
            const Text('kcal',
              style: TextStyle(color: _grey, fontSize: 12)),
          ]),
        ])),
      const SizedBox(width: 20),
      // Macro bars
      Expanded(child: Column(children: [
        _MacroRow('Protein', protein, proteinGoal, 'g'),
        const SizedBox(height: 16),
        _MacroRow('Carbs',   carbs,   carbGoal,    'g'),
        const SizedBox(height: 16),
        _MacroRow('Fat',     fat,     fatGoal,     'g'),
      ])),
    ]));
}

class _MacroRow extends StatelessWidget {
  final String label, unit;
  final double value, goal;
  const _MacroRow(this.label, this.value, this.goal, this.unit);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
          style: const TextStyle(color: _white, fontSize: 13)),
        Text('${value.toInt()}/${goal.toInt()}$unit',
          style: const TextStyle(color: _grey, fontSize: 12)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: goal == 0 ? 0 : (value / goal).clamp(0.0, 1.0),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: const AlwaysStoppedAnimation(_brand),
          minHeight: 5)),
    ]);
}

// ── Horseshoe ring painter ─────────────────────────────────────────────────
class _HorseshoeRing extends CustomPainter {
  final double progress;
  const _HorseshoeRing({required this.progress});

  // 270° arc, gap at bottom (7:30 → 4:30 clockwise over the top)
  static const _start = 3 * pi / 4;  // 135°
  static const _sweep = 3 * pi / 2;  // 270°
  static const _sw    = 13.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c    = Offset(size.width / 2, size.height / 2);
    final r    = size.width / 2 - _sw / 2 - 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Dark track
    canvas.drawArc(rect, _start, _sweep, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..strokeWidth = _sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);

    // Gradient arc (always full — represents goal boundary)
    canvas.drawArc(rect, _start, _sweep, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: _start,
          endAngle: _start + _sweep,
          colors: const [Color(0xFF6366F1), Color(0xFFC084FC)],
        ).createShader(rect)
        ..strokeWidth = _sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_HorseshoeRing old) => old.progress != progress;
}

// ── Coach card ─────────────────────────────────────────────────────────────
class _CoachCard extends StatelessWidget {
  final double protein, cal, proteinGoal, calGoal;
  const _CoachCard({required this.protein, required this.cal,
    required this.proteinGoal, required this.calGoal});

  String get _message {
    final need = (proteinGoal - protein).clamp(0, proteinGoal).toInt();
    if (protein < proteinGoal * 0.3) {
      return 'You still need ${need}g protein today. Try adding '
          'chicken, Greek yogurt, or a protein shake.';
    }
    if (cal < calGoal * 0.5) {
      return 'You\'re halfway there! Keep fueling up with '
          'balanced, protein-rich meals.';
    }
    return 'Great progress today! Stay consistent and hit your '
        'remaining macro targets.';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _brand.withValues(alpha: 0.45)),
      boxShadow: [
        BoxShadow(
          color: _brand.withValues(alpha: 0.18),
          blurRadius: 20, spreadRadius: -4),
      ]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [
        Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 16),
        SizedBox(width: 6),
        Text('Nutrition Insight',
          style: TextStyle(color: Color(0xFFA855F7), fontSize: 13,
            fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ]),
      const SizedBox(height: 6),
      Text(_message,
        style: const TextStyle(color: _grey, fontSize: 14, height: 1.45)),
    ]));
}

// ── Water card ─────────────────────────────────────────────────────────────
class _WaterCard extends StatelessWidget {
  final int glasses;
  final ValueChanged<int> onTap;
  const _WaterCard({required this.glasses, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Water',
        style: TextStyle(color: _white, fontSize: 16,
          fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Row(
            children: List.generate(8, (i) => Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: Icon(
                  i < glasses
                    ? Icons.water_drop
                    : Icons.water_drop_outlined,
                  color: i < glasses
                    ? _blue
                    : _grey.withValues(alpha: 0.35),
                  size: 24)))))),
        const SizedBox(width: 8),
        Text('$glasses / 8',
          style: const TextStyle(color: _grey, fontSize: 12)),
      ]),
    ]));
}

// ── Meal card ──────────────────────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  const _MealCard({required this.meal});

  IconData get _icon {
    final n = (meal['food_name'] as String? ?? '').toLowerCase();
    if (n.contains('salad') || n.contains('egg')) return Icons.eco;
    if (n.contains('shake') || n.contains('protein')) return Icons.local_drink;
    if (n.contains('chicken') || n.contains('bowl')) return Icons.rice_bowl;
    if (n.contains('avocado')) return Icons.brunch_dining;
    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    final name    = meal['food_name'] as String? ?? 'Meal';
    final cal     = (meal['calories'] as num?)?.toDouble() ?? 0;
    final protein = (meal['protein']  as num?)?.toDouble() ?? 0;
    final fat     = (meal['fat']      as num?)?.toDouble() ?? 0;
    final carbs   = (meal['carbs']    as num?)?.toDouble() ?? 0;
    final maxVal  = [protein, fat, carbs, 1.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _brand, size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                style: const TextStyle(color: _white, fontSize: 16,
                  fontWeight: FontWeight.w700)),
              Text('${cal.toInt()} kcal',
                style: const TextStyle(color: _grey, fontSize: 12)),
            ])),
          Icon(Icons.more_horiz, color: _grey.withValues(alpha: 0.6), size: 20),
        ]),
        const SizedBox(height: 14),
        _MealMacro('Protein', protein, maxVal),
        const SizedBox(height: 8),
        _MealMacro('Fats',    fat,     maxVal),
        const SizedBox(height: 8),
        _MealMacro('Carbs',   carbs,   maxVal),
      ]));
  }
}

class _MealMacro extends StatelessWidget {
  final String label;
  final double value, maxVal;
  const _MealMacro(this.label, this.value, this.maxVal);

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 60,
      child: Text(label,
        style: const TextStyle(color: _white, fontSize: 14))),
    Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: maxVal == 0 ? 0 : (value / maxVal).clamp(0.0, 1.0),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: const AlwaysStoppedAnimation(_brand),
          minHeight: 6))),
    const SizedBox(width: 10),
    SizedBox(width: 32,
      child: Text('${value.toInt()}g',
        textAlign: TextAlign.right,
        style: const TextStyle(color: _white, fontSize: 14,
          fontWeight: FontWeight.w600))),
  ]);
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyMeals extends StatelessWidget {
  final String mealType;
  final VoidCallback onAdd;
  const _EmptyMeals({required this.mealType, required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Icon(Icons.restaurant_outlined,
        color: _brand.withValues(alpha: 0.4), size: 36),
      const SizedBox(height: 12),
      Text('No ${mealType}s logged',
        style: const TextStyle(color: _white, fontSize: 15,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Track your $mealType to hit your goals',
        style: TextStyle(color: _grey.withValues(alpha: 0.7), fontSize: 12)),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: onAdd,
        child: Text('+ Log a meal',
          style: const TextStyle(color: _brand, fontSize: 13,
            fontWeight: FontWeight.w600))),
    ]));
}

// ── Add Meal Sheet ─────────────────────────────────────────────────────────
class _AddMealSheet extends ConsumerStatefulWidget {
  final VoidCallback onLogged;
  const _AddMealSheet({required this.onLogged});
  @override
  ConsumerState<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<_AddMealSheet> {
  final _svc        = NutritionService();
  final _searchCtrl = TextEditingController();
  String _inputMode = 'manual';
  Food?  _selected;
  String _mealType  = 'breakfast';
  bool   _saving    = false;
  List<Food> _filtered = [];
  bool   _searchingOnline = false;
  Timer? _debounce;
  final _meals = ['breakfast', 'lunch', 'dinner', 'snack', 'protein_shake'];
  final _logged = <String>{};   // names of items logged this session

  @override
  void initState() {
    super.initState();
    _filtered = _svc.getSampleFoods();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text;
    // Instant local results from the common-foods list.
    setState(() => _filtered = _svc.searchFoods(q));
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _searchingOnline = false);
      return;
    }
    // Debounced search: cached foods table first (instant/offline), then the
    // OpenFoodFacts network results — each merged in without duplicates.
    setState(() => _searchingOnline = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      void merge(List<Food> more) {
        if (!mounted || _searchCtrl.text != q) return;
        final seen = _filtered.map((f) => f.name.toLowerCase()).toSet();
        setState(() => _filtered = [..._filtered, ...more.where((f) => seen.add(f.name.toLowerCase()))]);
      }
      merge(await _svc.searchFoodsCached(q));
      final online = await _svc.searchFoodsOnline(q);
      merge(online);
      if (mounted && _searchCtrl.text == q) setState(() => _searchingOnline = false);
    });
  }

  @override
  void dispose() { _debounce?.cancel(); _searchCtrl.dispose(); super.dispose(); }

  String _label(String m) =>
    m == 'protein_shake' ? 'Protein Shake'
      : m[0].toUpperCase() + m.substring(1);

  void _showMealError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFFFB4AB),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5)));
  }

  Future<void> _logFood(Food f, double servings) async {
    setState(() => _saving = true);
    try {
      await _svc.logMeal(
        mealType:    _mealType,
        foodName:    f.name,
        calories:    f.calories * servings,
        protein:     f.protein  * servings,
        carbs:       f.carbs    * servings,
        fat:         f.fat      * servings,
        servingSize: f.servingSize * servings,
        servingUnit: f.servingUnit);
      if (!mounted) return;
      widget.onLogged();
      setState(() { _saving = false; _selected = null; _logged.add(f.name); });
      await FoodAddedDialog.show(context,
        foodName: f.name,
        protein:  (f.protein * servings).toInt(),
        carbs:    (f.carbs   * servings).toInt(),
        fat:      (f.fat     * servings).toInt());
    } catch (e) {
      setState(() { _saving = false; _selected = null; });
      _showMealError('Could not log meal: $e');
    }
  }

  Future<void> _logFromScan(ScanResult r) async {
    setState(() => _saving = true);
    try {
      await _svc.logMeal(
        mealType:    _mealType,
        foodName:    r.name,
        calories:    r.calories,
        protein:     r.protein,
        carbs:       r.carbs,
        fat:         r.fat,
        servingSize: 1,
        servingUnit: 'serving');
      if (!mounted) return;
      widget.onLogged();
      setState(() => _saving = false);
      final ctx = context;
      Navigator.pop(ctx);
      FoodAddedDialog.show(ctx,
        foodName: r.name,
        protein:  r.protein.toInt(),
        carbs:    r.carbs.toInt(),
        fat:      r.fat.toInt());
    } catch (e) {
      setState(() => _saving = false);
      _showMealError('Could not log meal: $e');
    }
  }

  Future<void> _logFromBarcode(Map<String, dynamic> food) async {
    setState(() => _saving = true);
    final name    = food['name'] as String? ?? 'Scanned Food';
    final cal     = (food['calories'] as num?)?.toDouble() ?? 0;
    final protein = (food['protein'] as num?)?.toDouble() ?? 0;
    final carbs   = (food['carbs'] as num?)?.toDouble()  ?? 0;
    final fat     = (food['fat'] as num?)?.toDouble()    ?? 0;
    try {
      await _svc.logMeal(
        mealType:    _mealType,
        foodName:    name,
        calories:    cal,
        protein:     protein,
        carbs:       carbs,
        fat:         fat,
        servingSize: 1,
        servingUnit: 'serving');
      if (!mounted) return;
      widget.onLogged();
      setState(() => _saving = false);
      final ctx = context;
      Navigator.pop(ctx);
      FoodAddedDialog.show(ctx,
        foodName: name,
        protein:  protein.toInt(),
        carbs:    carbs.toInt(),
        fat:      fat.toInt());
    } catch (e) {
      setState(() => _saving = false);
      _showMealError('Could not log meal: $e');
    }
  }

  void _showAddCustomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomFoodSheet(
        mealType: _mealType,
        onSaved: (f) {
          setState(() {
            _svc.addCustomFood(f);
            _filtered = _svc.getSampleFoods();
          });
        }));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.88,
    maxChildSize: 0.96,
    minChildSize: 0.5,
    builder: (_, scroll) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(children: [
        // Purple radial glow at top
        Positioned(
          top: -60, left: 0, right: 0,
          child: Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 0.8,
                colors: [Color(0x55A855F7), Colors.transparent])))),

        // Sheet content
        Container(
          color: const Color(0xFF0A0A18),
          child: Column(children: [
            const SizedBox(height: 12),

            // ── Title row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(children: [
                const SizedBox(width: 36),
                Expanded(
                  child: const Text('Log Meal',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _white, fontSize: 26,
                      fontWeight: FontWeight.w800))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2))),
                    child: const Icon(Icons.close,
                      color: _white, size: 18))),
              ])),
            const SizedBox(height: 20),

            // ── Manual / AI Scan toggle ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08))),
                child: Row(children: [
                  Expanded(child: _PillTab('Manual',
                    _inputMode == 'manual',
                    () => setState(() => _inputMode = 'manual'))),
                  Expanded(child: _PillTab('AI Scan',
                    _inputMode == 'ai_scan',
                    () => setState(() => _inputMode = 'ai_scan'))),
                  Expanded(child: _PillTab('Barcode',
                    _inputMode == 'barcode',
                    () => setState(() => _inputMode = 'barcode'))),
                ]))),
            const SizedBox(height: 16),

            // ── Meal type chips ─────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _meals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final m = _meals[i];
                  final active = m == _mealType;
                  return GestureDetector(
                    onTap: () => setState(() => _mealType = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                          ? Colors.transparent
                          : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                            ? _brand
                            : Colors.white.withValues(alpha: 0.12),
                          width: active ? 1.5 : 1.0)),
                      child: Text(_label(m),
                        style: TextStyle(
                          color: active ? _brand : _grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))));
                })),
            const SizedBox(height: 14),

            // ── Search bar ──────────────────────────────────────────
            if (_inputMode == 'manual')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _brand.withValues(alpha: 0.5), width: 1.2)),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: _white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search foods...',
                      hintStyle: TextStyle(
                        color: _grey.withValues(alpha: 0.45), fontSize: 15),
                      prefixIcon: Icon(Icons.search,
                        color: _grey.withValues(alpha: 0.5), size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14)),
                    onTapOutside: (_) =>
                      FocusScope.of(context).unfocus()))),

            const SizedBox(height: 10),

            if (_searchingOnline && _inputMode == 'manual')
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 20, right: 20),
                child: Row(children: [
                  SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA855F7))),
                  SizedBox(width: 8),
                  Text('Searching food database…',
                    style: TextStyle(color: Color(0xFF888898), fontSize: 12)),
                ])),

            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: _inputMode == 'barcode'
                ? BarcodeScanView(onFound: _logFromBarcode)
                : _inputMode == 'ai_scan'
                ? AiScanView(onAccept: _logFromScan)
                : _selected != null
                ? _FoodDetail(
                    key: ValueKey(_selected!.name),
                    food:   _selected!,
                    saving: _saving,
                    onLog:  (s) => _logFood(_selected!, s),
                    onBack: () => setState(() => _selected = null))
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: _filtered.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _filtered.length) {
                        return _AddCustomRow(
                          query: _searchCtrl.text,
                          onTap: _showAddCustomSheet);
                      }
                      final f = _filtered[i];
                      return _FoodRow(
                        food: f,
                        logged: _logged.contains(f.name),
                        onSelect: () => setState(() => _selected = f),
                        onQuickAdd: () => _logFood(f, 1.0));
                    })),
          ])),
      ])));
}

// ── Food list row ──────────────────────────────────────────────────────────
class _FoodRow extends StatelessWidget {
  final Food food;
  final bool logged;
  final VoidCallback onSelect, onQuickAdd;
  const _FoodRow({required this.food, required this.logged,
    required this.onSelect, required this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111125),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: logged
            ? _brand.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.08))),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: onSelect,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: logged
                      ? _brand.withValues(alpha: 0.3)
                      : _brand.withValues(alpha: 0.18)),
                  alignment: Alignment.center,
                  child: logged
                    ? const Icon(Icons.check, color: _brand, size: 20)
                    : Text(food.name[0],
                        style: const TextStyle(color: _brand,
                          fontSize: 18, fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name,
                        style: const TextStyle(color: _white,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${food.brand} · '
                          '${food.servingSize.toInt()}${food.servingUnit}',
                        style: TextStyle(
                          color: _grey.withValues(alpha: 0.6), fontSize: 12)),
                    ])),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${food.calories.toInt()} kcal',
                      style: const TextStyle(color: _brand,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('P: ${food.protein.toInt()}g',
                      style: TextStyle(
                        color: _grey.withValues(alpha: 0.6), fontSize: 12)),
                  ]),
              ])))),
        GestureDetector(
          onTap: onQuickAdd,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brand.withValues(alpha: 0.15),
                border: Border.all(color: _brand.withValues(alpha: 0.45))),
              child: const Icon(Icons.add, color: _brand, size: 18)))),
      ]));
  }
}

class _AddCustomRow extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  const _AddCustomRow({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brand.withValues(alpha: 0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_circle_outline,
          color: _brand.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 8),
        Text(
          query.isEmpty ? 'Add custom food' : 'Add "$query" manually',
          style: TextStyle(color: _brand.withValues(alpha: 0.8),
            fontSize: 14, fontWeight: FontWeight.w600)),
      ])));
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PillTab(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: active
          ? const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)])
          : null,
        borderRadius: BorderRadius.circular(999),
        boxShadow: active
          ? [BoxShadow(
              color: _brand.withValues(alpha: 0.45),
              blurRadius: 14, spreadRadius: -2)]
          : null),
      alignment: Alignment.center,
      child: Text(label,
        style: TextStyle(
          color: active ? _white : _grey.withValues(alpha: 0.55),
          fontSize: 15, fontWeight: FontWeight.w700))));
}

// ── Food Detail ────────────────────────────────────────────────────────────
class _FoodDetail extends StatefulWidget {
  final Food food;
  final bool saving;
  final void Function(double servings) onLog;
  final VoidCallback onBack;
  const _FoodDetail({super.key, required this.food, required this.saving,
    required this.onLog, required this.onBack});
  @override
  State<_FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<_FoodDetail> {
  double _servings = 1.0;

  @override
  Widget build(BuildContext context) {
    final f    = widget.food;
    final cal  = (f.calories * _servings).toInt();
    final prot = (f.protein  * _servings).toInt();
    final carb = (f.carbs    * _servings).toInt();
    final fat  = (f.fat      * _servings).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Header ────────────────────────────────────────────────
          Row(children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const Icon(Icons.chevron_left, color: _grey, size: 30)),
            Expanded(
              child: Text(f.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _white, fontSize: 20,
                  fontWeight: FontWeight.w700))),
            const SizedBox(width: 30),
          ]),
          const SizedBox(height: 14),

          // ── 2×2 macro grid ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16142A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09))),
            child: Column(children: [
              IntrinsicHeight(
                child: Row(children: [
                  Expanded(child: _MacroCell(cal.toString(),  'Calories')),
                  VerticalDivider(width: 1,
                    color: Colors.white.withValues(alpha: 0.08)),
                  Expanded(child: _MacroCell(prot.toString(), 'Protein (g)')),
                ])),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              IntrinsicHeight(
                child: Row(children: [
                  Expanded(child: _MacroCell(carb.toString(), 'Carbs (g)')),
                  VerticalDivider(width: 1,
                    color: Colors.white.withValues(alpha: 0.08)),
                  Expanded(child: _MacroCell(fat.toString(),  'Fat (g)')),
                ])),
            ])),
          const SizedBox(height: 14),

          // ── Servings card ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16142A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09))),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Servings (${f.servingSize.toInt()}${f.servingUnit})',
                    style: const TextStyle(color: _white, fontSize: 16,
                      fontWeight: FontWeight.w700)),
                  Text(_servings.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFC4B5FD), fontSize: 30,
                      fontWeight: FontWeight.w700)),
                ]),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 5,
                  activeTrackColor: _brand,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  thumbColor: _brand,
                  thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 13),
                  overlayColor: _brand.withValues(alpha: 0.2),
                  showValueIndicator: ShowValueIndicator.never),
                child: Slider(
                  value: _servings, min: 0.5, max: 5, divisions: 9,
                  onChanged: (v) => setState(() => _servings = v))),
            ])),
          const SizedBox(height: 20),

          // ── Log button ────────────────────────────────────────────
          GestureDetector(
            onTap: widget.saving ? null : () => widget.onLog(_servings),
            child: Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: widget.saving
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFB44CF0)]),
                color: widget.saving ? _grey.withValues(alpha: 0.3) : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.saving ? null : [
                  BoxShadow(color: _brand.withValues(alpha: 0.45),
                    blurRadius: 20, offset: const Offset(0, 6))]),
              child: widget.saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: _white, strokeWidth: 2.5))
                : Text('Log ${f.name}',
                    style: const TextStyle(color: _white, fontSize: 17,
                      fontWeight: FontWeight.w800)))),
        ]));
  }
}

class _MacroCell extends StatelessWidget {
  final String value, label;
  const _MacroCell(this.value, this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
        style: const TextStyle(
          color: Color(0xFFC4B5FD), fontSize: 46,
          fontWeight: FontWeight.w300, height: 1.0)),
      const SizedBox(height: 8),
      Text(label,
        style: TextStyle(color: _grey.withValues(alpha: 0.75), fontSize: 13)),
    ]));
}

// ── Custom food entry sheet ────────────────────────────────────────────────
class _CustomFoodSheet extends StatefulWidget {
  final String mealType;
  final void Function(Food) onSaved;
  const _CustomFoodSheet({required this.mealType, required this.onSaved});
  @override
  State<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<_CustomFoodSheet> {
  final _name     = TextEditingController();
  final _cal      = TextEditingController();
  final _protein  = TextEditingController();
  final _carbs    = TextEditingController();
  final _fat      = TextEditingController();
  final _serving  = TextEditingController(text: '100');

  @override
  void dispose() {
    for (final c in [_name, _cal, _protein, _carbs, _fat, _serving]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    final food = Food(
      id:          'custom_${DateTime.now().millisecondsSinceEpoch}',
      name:        n,
      brand:       'Custom',
      calories:    double.tryParse(_cal.text)     ?? 0,
      protein:     double.tryParse(_protein.text) ?? 0,
      carbs:       double.tryParse(_carbs.text)   ?? 0,
      fat:         double.tryParse(_fat.text)      ?? 0,
      fiber:       0,
      sugar:       0,
      servingSize: double.tryParse(_serving.text) ?? 100,
      servingUnit: 'g');
    widget.onSaved(food);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF111120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Add Custom Food',
          style: TextStyle(color: _white, fontSize: 20,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        _CustomField(_name,    'Food name',     TextInputType.text),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _CustomField(_cal,     'Calories',  TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _CustomField(_serving, 'Serving (g)', TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _CustomField(_protein, 'Protein (g)', TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _CustomField(_carbs,   'Carbs (g)',   TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _CustomField(_fat,     'Fat (g)',     TextInputType.number)),
        ]),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _save,
          child: Container(
            height: 54, alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFB44CF0)]),
              borderRadius: BorderRadius.circular(14)),
            child: const Text('Add to List',
              style: TextStyle(color: _white, fontSize: 16,
                fontWeight: FontWeight.w700)))),
      ]));
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType type;
  const _CustomField(this.ctrl, this.hint, this.type);

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    style: const TextStyle(color: _white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _grey.withValues(alpha: 0.45), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brand)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 12)));
}
