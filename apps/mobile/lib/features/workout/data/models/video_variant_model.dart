class VideoVariant {
  final String url;
  final String label; // 'Tutorial' | 'Beginner' | 'Intermediate' | 'Advanced' | 'Form Correction' | 'Warm-up'
  final String type;  // 'youtube' | 'vimeo' | 'upload'

  const VideoVariant({required this.url, required this.label, required this.type});

  factory VideoVariant.fromJson(Map<String, dynamic> j) => VideoVariant(
    url:   j['url']   as String? ?? '',
    label: j['label'] as String? ?? 'Tutorial',
    type:  j['type']  as String? ?? detectType(j['url'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {'url': url, 'label': label, 'type': type};

  static String detectType(String url) {
    if (url.contains('youtu')) return 'youtube';
    if (url.contains('vimeo')) return 'vimeo';
    return 'upload';
  }

  bool get isYoutube => type == 'youtube';
  bool get isVimeo   => type == 'vimeo';
  bool get isUpload  => type == 'upload';
}
