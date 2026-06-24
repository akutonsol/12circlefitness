// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final _registered = <String>{};

/// Web: embed a YouTube video in-app via an iframe (privacy-enhanced domain).
Widget? buildInAppVideo(String youtubeId) {
  final viewType = 'yt_$youtubeId';
  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final el = html.IFrameElement()
        ..src = 'https://www.youtube-nocookie.com/embed/$youtubeId?rel=0&modestbranding=1'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true;
      return el;
    });
  }
  return HtmlElementView(viewType: viewType);
}
