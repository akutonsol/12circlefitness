import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/rest_alarm.dart';

class RestTimerWidget extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;
  final ValueChanged<int>? onTick; // reports remaining seconds (for a mini view)

  const RestTimerWidget({
    super.key,
    required this.seconds,
    required this.onComplete,
    this.onTick,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    // Defer the first tick: initState runs during the parent's build, and onTick
    // calls setState on the parent (which would assert "setState during build").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTick?.call(_remaining);
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        widget.onTick?.call(0);
        playRestAlarm(); // loud beep + haptic so the user knows rest is over
        widget.onComplete();
      } else {
        setState(() => _remaining--);
        widget.onTick?.call(_remaining);
        // Spoken countdown over the final 10 seconds.
        if (_remaining <= 10 && _remaining >= 1) speakRest('$_remaining');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.seconds;
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
