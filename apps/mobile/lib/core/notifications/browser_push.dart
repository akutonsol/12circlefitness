// Conditional export: real browser notifications on web, no-op elsewhere.
export 'browser_push_stub.dart'
    if (dart.library.html) 'browser_push_web.dart';
