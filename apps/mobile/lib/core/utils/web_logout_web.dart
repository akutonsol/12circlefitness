// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Force a clean reload so no stale session/router state remains. We do NOT
/// change the hash first — that would fire an in-app GoRouter navigation
/// (ShellRoute teardown) mid-logout and crash. A plain reload cold-starts the
/// app signed-out, and the route guard then redirects to login.
void reloadForLogout() {
  html.window.location.reload();
}

/// Rewrites the URL to just its path (drops ?query and #hash) without reloading.
/// Used after consuming an OAuth return so a used/expired auth code or error
/// fragment isn't replayed if the user reloads or restores the tab.
void clearAuthParamsFromUrl() {
  html.window.history.replaceState(null, '', html.window.location.pathname);
}
