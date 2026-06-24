import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/rest_alarm.dart';

/// Wall-clock rest countdown with an overtime alarm. Counts down to 0 (spoken
/// cues), then — if the user hasn't started the next set — counts UP in flashing
/// red with a siren until dismissed (the active screen clears it when a weight
/// field is focused). [totalSeconds] is the original duration for the ring.
class RestTimerWidget extends StatefulWidget {
  final DateTime endTime;
  final int totalSeconds;
  final VoidCallback onComplete; // skip / dismiss
  final ValueChanged<int>? onTick; // remaining seconds (0 in overtime)

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
  int _overtime = 0;
  int? _lastSpoken;
  bool _warned30 = false;
  bool _sirenOn = false;
  bool _flash = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final diff = widget.endTime.difference(DateTime.now()).inMilliseconds / 1000.0;
    _remaining = diff > 0 ? diff.ceil() : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTick?.call(_remaining);
    });
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final diff = widget.endTime.difference(DateTime.now()).inMilliseconds / 1000.0;
    if (diff > 0) {
      final rem = diff.ceil();
      if (rem != _remaining) {
        setState(() => _remaining = rem);
        widget.onTick?.call(rem);
        if (rem == 30 && widget.totalSeconds > 30 && !_warned30) {
          _warned30 = true;
          speakRest('30 seconds left');
        }
        if (rem <= 12 && rem >= 1 && rem != _lastSpoken) {
          _lastSpoken = rem;
          speakRest('$rem');
        }
      }
    } else {
      // ── Overtime ──
      if (!_sirenOn) {
        _sirenOn = true;
        speakRest('Rest over. Get moving.');
        startRestSiren();
        widget.onTick?.call(0);
      }
      final over = (-diff).floor();
      setState(() {
        _remaining = 0;
        _overtime = over;
        _flash = !_flash; // ~250ms blink
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    stopRestSiren(); // clearing the timer (dismiss/skip/navigate) stops the siren
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overtime = _overtime > 0;
    final ending = _remaining <= 12;
    final accent = overtime ? AppColors.error : (ending ? AppColors.error : AppColors.purple);

    if (overtime) {
      final m = _overtime ~/ 60;
      final s = _overtime % 60;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _flash ? AppColors.error.withValues(alpha: 0.30) : AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error, width: _flash ? 2 : 1),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Text('OVERTIME', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(width: 8),
              Text('+${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.error, fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
            const Text('Start your next set to stop the siren',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: widget.onComplete,
            child: const Text('STOP',
              style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ]),
      );
    }

    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final progress = widget.totalSeconds > 0
        ? (_remaining / widget.totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Icon(Icons.timer_outlined, color: accent, size: 18),
        const SizedBox(width: 8),
        const Text('Rest', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text('${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(color: ending ? AppColors.error : AppColors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress, minHeight: 6,
              backgroundColor: AppColors.surfaceDarkElevated,
              valueColor: AlwaysStoppedAnimation<Color>(accent)),
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
