import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/progress_model.dart';

class WeightChart extends StatelessWidget {
  final List<WeightLog> logs;

  const WeightChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox();

    final minWeight = logs.map((l) => l.weight).reduce((a, b) => a < b ? a : b) - 1;
    final maxWeight = logs.map((l) => l.weight).reduce((a, b) => a > b ? a : b) + 1;
    final range = maxWeight - minWeight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceDarkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weight Progress', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${logs.first.weight} → ${logs.last.weight} kg', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _WeightChartPainter(logs: logs, minWeight: minWeight, range: range),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(logs.first.loggedAt), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              Text(_formatDate(logs.last.loggedAt), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}';
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightLog> logs;
  final double minWeight;
  final double range;

  _WeightChartPainter({required this.logs, required this.minWeight, required this.range});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.purple
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.purple.withValues(alpha: 0.3), AppColors.purple.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.purple
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppColors.bgDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final gridPaint = Paint()
      ..color = AppColors.surfaceDarkElevated
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = logs.asMap().entries.map((entry) {
      final x = size.width * entry.key / (logs.length - 1);
      final y = size.height - (size.height * (entry.value.weight - minWeight) / range);
      return Offset(x, y);
    }).toList();

    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final point in points) fillPath.lineTo(point.dx, point.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
