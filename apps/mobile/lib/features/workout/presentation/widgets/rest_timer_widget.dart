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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('Rest Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceDarkElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onComplete,
            child: const Text('Skip Rest', style: TextStyle(color: AppColors.purple)),
          ),
        ],
      ),
    );
  }
}
