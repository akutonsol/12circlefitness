// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> showBrowserNotification(String title, String body) async {
  if (!html.Notification.supported) return;
  final permission = await html.Notification.requestPermission();
  if (permission == 'granted') {
    html.Notification(title, body: body);
  }
}
