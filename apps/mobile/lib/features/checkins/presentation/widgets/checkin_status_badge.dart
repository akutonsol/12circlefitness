import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/checkin_model.dart';

class CheckinStatusBadge extends StatelessWidget {
  final CheckinStatus status;

  const CheckinStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case CheckinStatus.pending:
        color = AppColors.warning;
        label = 'Due';
        icon = Icons.schedule;
        break;
      case CheckinStatus.submitted:
        color = AppColors.purple;
        label = 'Submitted';
        icon = Icons.check_circle_outline;
        break;
      case CheckinStatus.reviewed:
        color = AppColors.success;
        label = 'Reviewed';
        icon = Icons.verified_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
