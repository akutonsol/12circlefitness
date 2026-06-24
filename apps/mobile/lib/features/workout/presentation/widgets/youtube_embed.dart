/// In-app YouTube embed (web) — returns null off web so callers can fall back.
export 'youtube_embed_stub.dart'
    if (dart.library.html) 'youtube_embed_web.dart';
