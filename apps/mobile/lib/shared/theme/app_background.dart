import 'package:flutter/material.dart';

/// The app's signature backdrop — a deep navy→purple gradient matching the
/// home screen. Use instead of flat black so every screen feels cohesive.
const appBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF181030), // purple-navy top
    Color(0xFF0B1326), // navy (home base)
    Color(0xFF080A14), // deep navy bottom
  ],
  stops: [0.0, 0.45, 1.0],
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
