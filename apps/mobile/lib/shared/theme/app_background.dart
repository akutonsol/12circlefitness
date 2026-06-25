import 'package:flutter/material.dart';

/// The app's signature backdrop — a black→purple gradient matching the auth
/// screens. Use instead of flat black so every screen feels cohesive.
const appBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1230), // purple top
    Color(0xFF0C0A12), // black-purple base
    Color(0xFF070507), // near-black bottom
  ],
  stops: [0.0, 0.4, 1.0],
);

/// Wraps [child] in the signature gradient. Put your screen body inside and
/// keep inner surfaces translucent so the gradient shows through.
class AppGradientBackground extends StatelessWidget {
  final Widget child;
  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: child,
      );
}
