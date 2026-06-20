import 'package:flutter/material.dart';
import '../../../core/config/stripe_config.dart';
import 'embedded_checkout.dart';

const _bg    = Color(0xFF030303);
const _white = Colors.white;

/// Hosts Stripe Embedded Checkout in-app (web). Stripe redirects the iframe to
/// checkout_complete.html on success, which sends the app to /payment-success.
class EmbeddedCheckoutScreen extends StatelessWidget {
  final String clientSecret;
  const EmbeddedCheckoutScreen({super.key, required this.clientSecret});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _white),
        title: const Text('Checkout',
            style: TextStyle(color: _white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: embeddedCheckoutView(
          publishableKey: stripePublishableKey,
          clientSecret: clientSecret,
        ),
      ),
    );
  }
}
