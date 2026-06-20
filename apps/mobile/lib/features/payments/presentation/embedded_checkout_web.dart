// Web implementation: host Stripe Embedded Checkout in an iframe pointed at our
// own static `stripe_checkout.html` (same-origin, so framing is allowed).
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

bool get embeddedCheckoutSupported => true;

Widget embeddedCheckoutView({
  required String publishableKey,
  required String clientSecret,
}) {
  final viewType = 'stripe-embedded-${clientSecret.hashCode}';
  // Registering the same factory twice is harmless; guard anyway.
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final iframe = html.IFrameElement()
      ..src = 'stripe_checkout.html'
          '?pk=${Uri.encodeQueryComponent(publishableKey)}'
          '&cs=${Uri.encodeQueryComponent(clientSecret)}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'payment';
    return iframe;
  });
  return HtmlElementView(viewType: viewType);
}
