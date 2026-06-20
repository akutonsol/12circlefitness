// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Force a clean reload to login so no stale session/router state remains.
void reloadForLogout() {
  html.window.location.hash = '#/login';
  html.window.location.reload();
}
