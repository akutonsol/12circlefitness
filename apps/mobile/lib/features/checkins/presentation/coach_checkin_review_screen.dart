import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/checkin_provider.dart';
import '../../auth/domain/auth_provider.dart';

class CoachCheckinReviewScreen extends ConsumerStatefulWidget {
  const CoachCheckinReviewScreen({super.key});

  @override
  ConsumerState<CoachCheckinReviewScreen> createState() =>
      _CoachCheckinReviewScreenState();
}

class _CoachCheckinReviewScreenState
    extends ConsumerState<CoachCheckinReviewScreen> {
  final _messageCtrl = TextEditingController();
  final _recCtrl = TextEditingController();
  final List<String> _recommendations = [];
  bool _saving = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _recCtrl.dispose();
    super.dispose();
  }

  void _addRecommendation() {
    final text = _recCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _recommendations.add(text);
      _recCtrl.clear();
    });
  }

  Future<void> _submit(Map<String, dynamic> checkin) async {
    if (_messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a feedback message.')),
      );
      return;
    }
    setState(() => _saving = true);
    final service = ref.read(weeklyCheckinServiceProvider);
    final coachName = ref.read(currentUserDisplayNameProvider);
    final ok = await service.submitCoachFeedback(
      checkinId: checkin['id'] as String,
      message: _messageCtrl.text.trim(),
      recommendations: _recommendations,
      coachName: coachName,
    );
    setState(() => _saving = false);

    if (!mounted) return;
    if (ok) {
      ref.invalidate(coachSubmittedCheckinsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feedback. Try again.')),
      );
    }
  }

  String _clientName(Map<String, dynamic> checkin) {
    final profile = checkin['user_profiles'] as Map<String, dynamic>?;
    if (profile == null) return 'Client';
    final fn = profile['first_name'] as String? ?? '';
    final ln = profile['last_name'] as String? ?? '';
    final name = '$fn $ln'.trim();
    return name.isEmpty ? 'Client' : name;
  }

  @override
  Widget build(BuildContext context) {
    final checkin = ref.watch(selectedCoachCheckinProvider);

    if (checkin == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          title: const Text("Review Check-In",
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text("No check-in selected",
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final mood = checkin['mood'] as int?;
    final energy = checkin['energy'] as int?;
    final stress = checkin['stress_level'] as int?;
    final sleep = (checkin['sleep_hours_avg'] as num?)?.toDouble();
    final notes = checkin['notes'] as String?;
    final score = (checkin['overall_score'] as num?)?.toDouble() ?? 0;
    final weekNumber = checkin['week_number'] as int?;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text("Review Check-In",
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_clientName(checkin),
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    if (weekNumber != null)
                      Text("Week $weekNumber",
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                if (score > 0)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _scoreColor(score).withValues(alpha: 0.15),
                      border: Border.all(color: _scoreColor(score).withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(score.toStringAsFixed(1),
                        style: TextStyle(
                            color: _scoreColor(score),
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            const Text("Client Summary",
                style: TextStyle(
                    color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyles.premiumCardDecoration,
              child: Column(
                children: [
                  if (mood != null) _SummaryRow("Mood", _moodLabel(mood), Icons.sentiment_satisfied_outlined),
                  if (energy != null) _SummaryRow("Energy", "$energy/5", Icons.bolt),
                  if (stress != null) _SummaryRow("Stress", "$stress/5", Icons.psychology_outlined),
                  if (sleep != null) _SummaryRow("Avg Sleep", "${sleep.toStringAsFixed(1)} hrs", Icons.bedtime_outlined),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(children: [
                        const Icon(Icons.chat_bubble_outline, color: AppColors.purple, size: 16),
                        const SizedBox(width: 8),
                        Text("Notes",
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(notes,
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 13, height: 1.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Your Feedback",
                style: TextStyle(
                    color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              decoration: AppStyles.premiumCardDecoration,
              child: TextField(
                controller: _messageCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppColors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Write feedback for this client's week...",
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            const SizedBox(height: 16),

            const Text("Recommendations",
                style: TextStyle(
                    color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: AppStyles.premiumCardDecoration,
                    child: TextField(
                      controller: _recCtrl,
                      style: const TextStyle(color: AppColors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "e.g. Add a 4th rest day",
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _addRecommendation(),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addRecommendation,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (_recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._recommendations.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceDarkElevated),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, color: AppColors.purple, size: 18),
                          Expanded(
                            child: Text(entry.value,
                                style: const TextStyle(color: AppColors.white, fontSize: 13)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _recommendations.removeAt(entry.key)),
                            child: const Icon(Icons.close, color: AppColors.textTertiary, size: 16),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _submit(checkin),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Submit Feedback",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return AppColors.warning;
    return AppColors.error;
  }

  String _moodLabel(int mood) {
    const labels = ['', 'Rough', 'Meh', 'Good', 'Great', 'Amazing'];
    if (mood < 1 || mood > 5) return '$mood';
    return labels[mood];
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.purple, size: 16),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
            Text(value,
                style: const TextStyle(
                    color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
