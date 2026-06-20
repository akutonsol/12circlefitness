// Web implementation: show a native browser notification + request permission.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool get supportsBrowserPush => html.Notification.supported;

Future<void> ensurePermission() async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission == 'default') {
    await html.Notification.requestPermission();
  }
}

void showBrowserNotification(String title, String body) {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;
  // Constructing the notification displays it.
  html.Notification(title, body: body, icon: 'favicon.png');
}
