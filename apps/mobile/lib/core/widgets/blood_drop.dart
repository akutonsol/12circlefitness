import 'package:flutter/material.dart';

/// An animated blood drop: the main droplet gently swells and bobs while a
/// smaller droplet periodically forms at the tip, falls, and fades — like a
/// real drip. Used for the Women's Health surfaces.
class BloodDrop extends StatefulWidget {
  final double size;
  final Color color;
  const BloodDrop({super.key, this.size = 22, this.color = const Color(0xFFFF5D7A)});

  @override
  State<BloodDrop> createState() => _BloodDropState();
}

class _BloodDropState extends State<BloodDrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // One full drip cycle. The painter maps phases within this.
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _BloodDropPainter(t: _c.value, color: widget.color),
          ),
        ),
      );
}

class _BloodDropPainter extends CustomPainter {
  final double t; // 0..1 over the cycle
  final Color color;
  const _BloodDropPainter({required this.t, required this.color});

  // A teardrop: pointed at the top, bulbous at the bottom.
  Path _drop(double cx, double cy, double w, double h) {
    final path = Path();
    final top = cy - h / 2;
    final bottom = cy + h / 2;
    final r = w / 2;
    path.moveTo(cx, top);
    path.cubicTo(cx + r * 0.55, top + h * 0.34, cx + r, cy + h * 0.06, cx + r, cy + h * 0.16);
    path.arcToPoint(Offset(cx - r, cy + h * 0.16),
        radius: Radius.circular(r), clockwise: true);
    path.cubicTo(cx - r, cy + h * 0.06, cx - r * 0.55, top + h * 0.34, cx, top);
    path.close();
    // pull the very bottom round
    final bowl = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, bottom - r), radius: r));
    return Path.combine(PathOperation.union, path, bowl);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;

    // Main drop: gentle swell + bob using a smooth 0..1..0 pulse.
    final pulse = (0.5 - (t - 0.5).abs()) * 2; // triangle 0..1..0
    final swell = 1 + pulse * 0.07;
    final bob = pulse * 0.6;
    final dropW = w * 0.62 * swell;
    final dropH = w * 0.82 * swell;
    final mainCy = w * 0.46 + bob;

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.95), color],
      ).createShader(Rect.fromLTWH(0, 0, w, w));
    canvas.drawShadow(_drop(cx, mainCy, dropW, dropH), color.withValues(alpha: 0.5), 2, true);
    canvas.drawPath(_drop(cx, mainCy, dropW, dropH), fill);

    // Specular highlight.
    canvas.drawCircle(
      Offset(cx - dropW * 0.16, mainCy + dropH * 0.06),
      dropW * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Falling droplet: forms in the first third, falls + fades after.
    if (t > 0.35) {
      final f = ((t - 0.35) / 0.55).clamp(0.0, 1.0); // 0..1 fall progress
      final dy = mainCy + dropH * 0.5 + f * (w * 0.42);
      final ds = (1 - f) * w * 0.17 + w * 0.04;
      final op = (1 - f).clamp(0.0, 1.0);
      canvas.drawPath(
        _drop(cx, dy, ds * 1.1, ds * 1.5),
        Paint()..color = color.withValues(alpha: 0.9 * op),
      );
    }
  }

  @override
  bool shouldRepaint(_BloodDropPainter old) => old.t != t || old.color != color;
}
