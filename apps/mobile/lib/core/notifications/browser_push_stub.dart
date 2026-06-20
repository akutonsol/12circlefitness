// Non-web fallback (mobile uses OS notifications via a separate plugin later).
bool get supportsBrowserPush => false;
Future<void> ensurePermission() async {}
void showBrowserNotification(String title, String body) {}
