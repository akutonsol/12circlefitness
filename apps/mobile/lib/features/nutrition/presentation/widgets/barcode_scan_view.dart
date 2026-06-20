import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/nutrition_service.dart';

typedef BarcodeFoundCallback = void Function(Map<String, dynamic> food);

class BarcodeScanView extends StatefulWidget {
  final BarcodeFoundCallback onFound;
  const BarcodeScanView({super.key, required this.onFound});

  @override
  State<BarcodeScanView> createState() => _BarcodeScanViewState();
}

class _BarcodeScanViewState extends State<BarcodeScanView> {
  final _ctrl = MobileScannerController();
  bool _processing = false;
  String? _statusMessage;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null) return;

    setState(() { _processing = true; _statusMessage = 'Looking up barcode…'; });

    // Local foods table → OpenFoodFacts fallback.
    final result = await NutritionService().lookupBarcode(rawValue);

    if (!mounted) return;

    if (result != null) {
      widget.onFound(result);
    } else {
      setState(() {
        _statusMessage = 'Barcode $rawValue not found. Try the AI scan or search.';
        _processing = false;
      });
      // Resume scanning after 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _statusMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: _onDetect,
        ),

        // Scanning overlay
        Center(
          child: Container(
            width: 260,
            height: 130,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFA855F7), width: 2.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Corner brackets
        ..._corners(),

        // Status / instructions
        Positioned(
          bottom: 40,
          left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _statusMessage ?? 'Point camera at a food barcode',
                style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        if (_processing)
          const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7))),
      ],
    );
  }

  List<Widget> _corners() {
    const sz = 24.0;
    const thick = 3.0;
    const clr = Color(0xFFA855F7);
    const cy = 65.0;
    return [
      // top-left
      Positioned(
        left: (MediaQuery.of(context).size.width - 260) / 2,
        top: (MediaQuery.of(context).size.height / 2) - cy,
        child: _Corner(top: true, left: true, size: sz, thick: thick, color: clr)),
      // top-right
      Positioned(
        right: (MediaQuery.of(context).size.width - 260) / 2,
        top: (MediaQuery.of(context).size.height / 2) - cy,
        child: _Corner(top: true, left: false, size: sz, thick: thick, color: clr)),
      // bottom-left
      Positioned(
        left: (MediaQuery.of(context).size.width - 260) / 2,
        top: (MediaQuery.of(context).size.height / 2) + cy - sz,
        child: _Corner(top: false, left: true, size: sz, thick: thick, color: clr)),
      // bottom-right
      Positioned(
        right: (MediaQuery.of(context).size.width - 260) / 2,
        top: (MediaQuery.of(context).size.height / 2) + cy - sz,
        child: _Corner(top: false, left: false, size: sz, thick: thick, color: clr)),
    ];
  }
}

class _Corner extends StatelessWidget {
  final bool top, left;
  final double size, thick;
  final Color color;
  const _Corner({required this.top, required this.left,
    required this.size, required this.thick, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _CornerPainter(top, left, thick, color)),
  );
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  final double thick;
  final Color color;
  const _CornerPainter(this.top, this.left, this.thick, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thick
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final ex = left ? size.width : 0.0;
    final ey = top ? size.height : 0.0;
    canvas.drawLine(Offset(x, y), Offset(ex, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, ey), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
