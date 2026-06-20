// Conditional export: real iframe view on web, no-op stub elsewhere.
export 'embedded_checkout_stub.dart'
    if (dart.library.html) 'embedded_checkout_web.dart';
