// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final _registered = <String>{};

/// Web: in-app player for [src] — a YouTube id/URL or Vimeo URL (iframe), or a
/// direct video file (native <video> with controls). Returns null if [src] is
/// empty so callers can fall back.
Widget? buildInAppVideo(String src) {
  if (src.trim().isEmpty) return null;
  final viewType = 'vid_${src.hashCode}';
  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final yt = _youtubeId(src);
      if (yt != null) {
        return html.IFrameElement()
          ..src = 'https://www.youtube-nocookie.com/embed/$yt?rel=0&modestbranding=1'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
          ..allowFullscreen = true;
      }
      final vimeo = _vimeoId(src);
      if (vimeo != null) {
        return html.IFrameElement()
          ..src = 'https://player.vimeo.com/video/$vimeo'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
      }
      // Direct video file (mp4/webm/mov from storage, etc.).
      return html.VideoElement()
        ..src = src
        ..controls = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.background = '#000'
        ..setAttribute('playsinline', 'true');
    });
  }
  return HtmlElementView(viewType: viewType);
}

String? _youtubeId(String url) {
  for (final p in [
    RegExp(r'youtu\.be/([A-Za-z0-9_-]{6,})'),
    RegExp(r'youtube\.com/watch\?v=([A-Za-z0-9_-]{6,})'),
    RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{6,})'),
    RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{6,})'),
  ]) {
    final m = p.firstMatch(url);
    if (m != null) return m.group(1);
  }
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(url)) return url; // bare id
  return null;
}

String? _vimeoId(String url) =>
    RegExp(r'vimeo\.com/(?:video/)?(\d+)').firstMatch(url)?.group(1);
