// Non-web fallback: embedded checkout isn't available; callers use the hosted
// (redirect / WebView) flow instead.
import 'package:flutter/widgets.dart';

bool get embeddedCheckoutSupported => false;

Widget embeddedCheckoutView({
  required String publishableKey,
  required String clientSecret,
}) =>
    const SizedBox.shrink();
