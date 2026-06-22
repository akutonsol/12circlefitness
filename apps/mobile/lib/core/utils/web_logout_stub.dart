void reloadForLogout() {}

/// No-op off web. On web this strips OAuth/query/hash params from the URL so a
/// stale error or used auth code can't be replayed on reload.
void clearAuthParamsFromUrl() {}
