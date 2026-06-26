import 'package:flutter/material.dart';

/// The app's signature backdrop — a black→purple gradient matching the auth
/// screens. Use instead of flat black so every screen feels cohesive.
const appBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF100A18), // purple top
    Color(0xFF0A0A0B), // black-purple base
    Color(0xFF0C0911), // near-black bottom
  ],
  stops: [0.0, 0.4, 1.0],
);

/// Top-center purple bloom — rgba(138,61,240,0.20) → transparent.
const _topPurpleGlow = RadialGradient(
  center: Alignment.topCenter,
  radius: 1.1,
  colors: [Color(0x338A3DF0), Color(0x008A3DF0)],
  stops: [0.0, 0.62],
);

/// Bottom-right lavender bloom — rgba(176,107,255,0.13) → transparent.
const _bottomRightGlow = RadialGradient(
  center: Alignment.bottomRight,
  radius: 1.1,
  colors: [Color(0x21B06BFF), Color(0x00B06BFF)],
  stops: [0.0, 0.62],
);

/// Wraps [child] in the signature backdrop: a near-black base linear gradient
/// with a top-center purple bloom and a bottom-right lavender bloom layered on
/// top. Put your screen body inside and keep inner surfaces translucent so the
/// gradient shows through.
class AppGradientBackground extends StatelessWidget {
  final Widget child;
  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: appBackgroundGradient))),
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: _topPurpleGlow))),
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: _bottomRightGlow))),
          child,
        ],
      );
}
