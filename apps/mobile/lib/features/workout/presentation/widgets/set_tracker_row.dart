import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SetTrackerRow extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final double targetWeight; // always stored in kg
  final bool completed;
  final String? tempo;
  final String unit; // display unit: 'kg' or 'lb'
  // weight is reported back in kg (converted from the display unit).
  final Function(int reps, double weight, double? rpe, String? notes) onCompleted;
  // Fired when any field is edited (on blur), so values persist without having
  // to (re)tap the complete button. weight is in kg.
  final Function(int reps, double weight, double? rpe, String? notes)? onChanged;
  // Previously-logged values for this set (restored from the DB), so the fields
  // repopulate when returning to the workout. Null = nothing logged yet.
  final double? savedWeightKg;
  final int? savedReps;
  final double? savedRpe;
  final String? savedNotes;
  // Fired when the weight or reps field gains focus — used to dismiss the
  // rest/overtime alarm (the user is starting the next set).
  final VoidCallback? onWeightFocus;
  // Bodyweight exercises (plank, push-up…) don't require external load; the
  // weight field shows "BW" and is optional.
  final bool isBodyweight;

  const SetTrackerRow({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.completed,
    required this.onCompleted,
    this.onChanged,
    this.unit = 'kg',
    this.tempo,
    this.savedWeightKg,
    this.savedReps,
    this.savedRpe,
    this.savedNotes,
    this.onWeightFocus,
    this.isBodyweight = false,
  });

  static const double _kgPerLb = 0.45359237;
  double _toDisplay(double kg) => unit == 'lb' ? kg / _kgPerLb : kg;
  double _toKg(double display) => unit == 'lb' ? display * _kgPerLb : display;

  @override
  State<SetTrackerRow> createState() => _SetTrackerRowState();
}

class _SetTrackerRowState extends State<SetTrackerRow>
    with SingleTickerProviderStateMixin {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _rpeController;
  late TextEditingController _notesController;
  late final AnimationController _notesPulse;
  Timer? _debounce;
  final _weightFocus = FocusNode();
  final _repsFocus = FocusNode();
  final _rpeFocus = FocusNode();
  final _notesFocus = FocusNode();

  // Save shortly after the user stops typing (independent of focus/blur, which
  // is unreliable on web). Also fires immediately on blur/submit.
  void _scheduleEmit() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _emitChange);
  }
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    // Fields start from any saved value; otherwise empty (reps no longer
    // pre-fills the target — all three inputs start blank like weight/RPE).
    final savedWeightDisplay = (widget.savedWeightKg != null && widget.savedWeightKg! > 0)
        ? _fmt(widget._toDisplay(widget.savedWeightKg!)) : '';
    _repsController = TextEditingController(text: widget.savedReps?.toString() ?? '');
    _weightController = TextEditingController(text: savedWeightDisplay);
    _rpeController = TextEditingController(
        text: widget.savedRpe != null ? _fmt(widget.savedRpe!) : '');
    _notesController = TextEditingController(text: widget.savedNotes ?? '');
    _showNotes = (widget.savedNotes != null && widget.savedNotes!.isNotEmpty);
    // Persist edits when a field loses focus.
    for (final f in [_weightFocus, _repsFocus, _rpeFocus, _notesFocus]) {
      f.addListener(() { if (!f.hasFocus) _emitChange(); });
    }
    // Focusing the weight (or reps, for bodyweight) field = starting the next
    // set → dismiss the rest alarm.
    _weightFocus.addListener(() {
      if (_weightFocus.hasFocus) widget.onWeightFocus?.call();
    });
    _repsFocus.addListener(() {
      if (_repsFocus.hasFocus) widget.onWeightFocus?.call();
    });
    _notesPulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SetTrackerRow old) {
    super.didUpdateWidget(old);
    // Saved values may arrive after first build (async restore). Fill any field
    // the user hasn't typed into — deferred to post-frame because mutating a
    // controller during build asserts on the EditableText being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void fill(TextEditingController c, String? v) {
        if (v != null && v.isNotEmpty && c.text.isEmpty) c.text = v;
      }
      if (widget.savedReps != old.savedReps) fill(_repsController, widget.savedReps?.toString());
      if (widget.savedRpe != old.savedRpe) {
        fill(_rpeController, widget.savedRpe != null ? _fmt(widget.savedRpe!) : null);
      }
      if (widget.savedWeightKg != old.savedWeightKg &&
          widget.savedWeightKg != null && widget.savedWeightKg! > 0) {
        fill(_weightController, _fmt(widget._toDisplay(widget.savedWeightKg!)));
      }
      if (widget.savedNotes != old.savedNotes) {
        fill(_notesController, widget.savedNotes);
        if (widget.savedNotes != null && widget.savedNotes!.isNotEmpty && !_showNotes) {
          setState(() => _showNotes = true);
        }
      }
    });
  }

  void _emitChange() {
    final cb = widget.onChanged;
    if (cb == null) return;
    final reps = int.tryParse(_repsController.text) ?? widget.targetReps;
    final displayWeight =
        double.tryParse(_weightController.text) ?? widget._toDisplay(widget.targetWeight);
    final weightKg = widget._toKg(displayWeight);
    final rpe = double.tryParse(_rpeController.text);
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    cb(reps, weightKg, rpe, notes);
  }

  @override
  void dispose() {
    // Flush a pending debounced save (e.g. a note typed right before navigating
    // away) BEFORE disposing the controllers, so it isn't lost.
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _emitChange();
    }
    _repsController.dispose();
    _weightController.dispose();
    _rpeController.dispose();
    _notesController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _rpeFocus.dispose();
    _notesFocus.dispose();
    _notesPulse.dispose();
    _debounce?.cancel();
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
              Expanded(child: _buildInput(_weightController, widget.isBodyweight ? 'BW' : widget.unit, _weightFocus)),
              const SizedBox(width: 8),
              Expanded(child: _buildInput(_repsController, 'reps', _repsFocus)),
              const SizedBox(width: 8),
              Expanded(child: _buildInput(_rpeController, 'RPE', _rpeFocus)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showNotes = !_showNotes),
                child: AnimatedBuilder(
                  animation: _notesPulse,
                  builder: (context, child) {
                    // Gentle swell + glow when collapsed, so it reads as tappable.
                    final t = _showNotes ? 0.0
                        : Curves.easeInOut.transform(_notesPulse.value);
                    return Transform.scale(
                      scale: 1.0 + t * 0.18,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _showNotes
                              ? AppColors.purple.withValues(alpha: 0.2)
                              : AppColors.purple.withValues(alpha: 0.10 + t * 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.25 + t * 0.45),
                            width: 1),
                        ),
                        child: Icon(
                          Icons.notes_outlined,
                          color: _showNotes
                              ? AppColors.purple
                              : Color.lerp(AppColors.textTertiary, AppColors.purple, t),
                          size: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  final reps = int.tryParse(_repsController.text) ?? widget.targetReps;
                  // Field is in the display unit; convert back to kg for storage.
                  final displayWeight = double.tryParse(_weightController.text)
                      ?? widget._toDisplay(widget.targetWeight);
                  final weightKg = widget._toKg(displayWeight);
                  final rpe = double.tryParse(_rpeController.text);
                  final notes = _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim();
                  widget.onCompleted(reps, weightKg, rpe, notes);
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
              focusNode: _notesFocus,
              onChanged: (_) => _scheduleEmit(),
              onSubmitted: (_) => _emitChange(),
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

  // Trims trailing zeros so 88.18 lb shows cleanly (and 60.0 → 60).
  String _fmt(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }

  Widget _buildInput(TextEditingController controller, String hint, FocusNode focusNode) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      onChanged: (_) => _scheduleEmit(),
      onSubmitted: (_) => _emitChange(),
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
