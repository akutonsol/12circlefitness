import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SetTrackerRow extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final bool completed;
  final String? tempo;
  final Function(int reps, double weight, double? rpe, String? notes) onCompleted;

  const SetTrackerRow({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.completed,
    required this.onCompleted,
    this.tempo,
  });

  @override
  State<SetTrackerRow> createState() => _SetTrackerRowState();
}

class _SetTrackerRowState extends State<SetTrackerRow> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _rpeController;
  late TextEditingController _notesController;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.targetReps.toString());
    _weightController = TextEditingController(text: widget.targetWeight == 0 ? '' : widget.targetWeight.toString());
    _rpeController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _rpeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: widget.completed
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.completed
                  ? AppColors.success.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${widget.setNumber}',
                  style: TextStyle(
                    color: widget.completed ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildInput(_weightController, 'kg')),
              const SizedBox(width: 8),
              Expanded(child: _buildInput(_repsController, 'reps')),
              const SizedBox(width: 8),
              Expanded(child: _buildInput(_rpeController, 'RPE')),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showNotes = !_showNotes),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _showNotes
                        ? AppColors.purple.withValues(alpha: 0.2)
                        : AppColors.surfaceDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notes_outlined,
                    color: _showNotes ? AppColors.purple : AppColors.textTertiary,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  final reps = int.tryParse(_repsController.text) ?? widget.targetReps;
                  final weight = double.tryParse(_weightController.text) ?? widget.targetWeight;
                  final rpe = double.tryParse(_rpeController.text);
                  final notes = _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim();
                  widget.onCompleted(reps, weight, rpe, notes);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.completed ? AppColors.success : AppColors.surfaceDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.completed ? AppColors.success : AppColors.textTertiary,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    color: widget.completed ? AppColors.white : AppColors.textTertiary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.tempo != null)
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 4),
            child: Row(children: [
              const Icon(Icons.speed_outlined, size: 11, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('Tempo: ${widget.tempo}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
            ]),
          ),
        if (_showNotes)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
            child: TextField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.white, fontSize: 12),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Add set note...',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.surfaceDark,
      ),
    );
  }
}
