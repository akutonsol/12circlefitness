import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HabitProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final Widget child;

  const HabitProgressRing({
    super.key,
    required this.progress,
    required this.size,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: AppColors.surfaceDarkElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          child,
        ],
      ),
    );
  }
}
