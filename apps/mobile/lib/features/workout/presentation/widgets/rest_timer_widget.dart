import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/rest_alarm.dart';

/// Wall-clock rest countdown: computes remaining from [endTime] each tick (no
/// internal counter that can drift/jump), so it stays smooth across rebuilds and
/// resumes correctly after navigating away. [totalSeconds] is the original
/// duration, used only for the progress ring.
class RestTimerWidget extends StatefulWidget {
  final DateTime endTime;
  final int totalSeconds;
  final VoidCallback onComplete;
  final ValueChanged<int>? onTick; // reports remaining seconds (for a mini view)

  const RestTimerWidget({
    super.key,
    required this.endTime,
    required this.totalSeconds,
    required this.onComplete,
    this.onTick,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  int _remaining = 0;
  int? _lastSpoken;
  Timer? _timer;
  bool _done = false;

  int get _calcRemaining {
    final r = widget.endTime.difference(DateTime.now()).inMilliseconds / 1000.0;
    return r.ceil().clamp(0, 1 << 30);
  }

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining;
    // Defer the first tick: initState runs during the parent's build, and onTick
    // calls setState on the parent (which would assert "setState during build").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTick?.call(_remaining);
    });
    // Tick a bit faster than 1s so the display doesn't visibly stutter.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (_done) return;
    final rem = _calcRemaining;
    if (rem <= 0) {
      _done = true;
      _timer?.cancel();
      if (mounted) setState(() => _remaining = 0);
      widget.onTick?.call(0);
      playRestAlarm(); // loud beep + haptic so the user knows rest is over
      widget.onComplete();
      return;
    }
    if (rem != _remaining) {
      if (mounted) setState(() => _remaining = rem);
      widget.onTick?.call(rem);
      // Speak each whole number once, over the final 10 seconds.
      if (rem <= 10 && rem != _lastSpoken) {
        _lastSpoken = rem;
        speakRest('$rem');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds > 0
        ? (_remaining / widget.totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final ending = _remaining <= 10;

    // Compact horizontal banner — meant to sit fixed above the exercise list so
    // it's always visible and never shifts the scroll content.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (ending ? AppColors.error : AppColors.purple).withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Icon(Icons.timer_outlined, color: ending ? AppColors.error : AppColors.purple, size: 18),
        const SizedBox(width: 8),
        const Text('Rest', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: ending ? AppColors.error : AppColors.white,
            fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceDarkElevated,
              valueColor: AlwaysStoppedAnimation<Color>(ending ? AppColors.error : AppColors.purple)),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: widget.onComplete,
          child: const Text('SKIP',
            style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
      ]),
    );
  }
}
