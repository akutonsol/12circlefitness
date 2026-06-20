/// Stripe publishable key (client-safe — NOT the secret key).
/// Used to initialise Stripe.js for in-app Embedded Checkout on web.
///
/// Paste your test key below, or pass it at build time with:
///   flutter run -d chrome --dart-define=STRIPE_PK=pk_test_xxx
///
/// When empty, the app falls back to the hosted (redirect) checkout flow.
const String stripePublishableKey = String.fromEnvironment(
  'STRIPE_PK',
  defaultValue:
      'pk_test_51TjY6fLwsDN0E0HCYEjmJTW7kJlJAC81nHgNVtRfDpWJFcZ133ob0zSeSqJQoDw4BqqJsdlTOieOWSif2CYzzSrh00BXlrGnFb',
);
