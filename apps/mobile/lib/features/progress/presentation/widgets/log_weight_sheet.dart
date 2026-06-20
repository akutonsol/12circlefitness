import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/progress_model.dart';
import '../../domain/progress_provider.dart';

class LogWeightSheet extends ConsumerStatefulWidget {
  const LogWeightSheet({super.key});

  @override
  ConsumerState<LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends ConsumerState<LogWeightSheet> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  String _unit = 'kg';

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgDarkSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.surfaceDarkElevated, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Log Weight', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white, fontSize: 24),
                  decoration: InputDecoration(
                    hintText: '70.5',
                    suffixText: _unit,
                    suffixStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: ['kg', 'lbs'].map((unit) {
                    final isSelected = _unit == unit;
                    return GestureDetector(
                      onTap: () => setState(() => _unit = unit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.purple : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(unit, style: TextStyle(color: isSelected ? AppColors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(hintText: 'Notes (optional)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(_weightController.text);
              if (weight == null) return;
              ref.read(weightLogNotifierProvider.notifier).addLog(
                WeightLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  weight: weight,
                  unit: _unit,
                  loggedAt: DateTime.now(),
                  notes: _notesController.text.isEmpty ? null : _notesController.text,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Weight'),
          ),
        ],
      ),
    );
  }
}
