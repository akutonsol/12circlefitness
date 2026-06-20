import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/stripe_config.dart';
import '../domain/payment_provider.dart';
import 'embedded_checkout.dart';
import 'embedded_checkout_screen.dart';

/// Single entry point for starting a checkout. Uses in-app Embedded Checkout on
/// web when a publishable key is configured; otherwise falls back to the hosted
/// (redirect / external) flow. Returns true if a checkout was started.
Future<bool> launchCheckout(
  BuildContext context,
  WidgetRef ref, {
  required String kind,
  String? coachId,
  String? eventId,
  String? tier,
}) async {
  final svc = ref.read(paymentServiceProvider);

  final canEmbed = kIsWeb &&
      embeddedCheckoutSupported &&
      stripePublishableKey.isNotEmpty;

  if (canEmbed) {
    final clientSecret = await svc.createEmbeddedCheckout(
      kind: kind, coachId: coachId, eventId: eventId, tier: tier,
    );
    if (clientSecret != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmbeddedCheckoutScreen(clientSecret: clientSecret),
        ),
      );
      return true;
    }
    // Fall through to redirect if embedded couldn't start.
  }

  return svc.startCheckout(
    kind: kind, coachId: coachId, eventId: eventId, tier: tier,
  );
}
