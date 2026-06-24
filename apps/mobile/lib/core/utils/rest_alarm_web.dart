// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Web: play a short synthesized beep (built as an 8-bit PCM WAV data URL and
/// played via an AudioElement — no asset, no removed dart:web_audio library).
void playRestAlarm() {
  try {
    final audio = html.AudioElement(_beepDataUrl())..volume = 1.0;
    audio.play();
  } catch (_) {}
}

/// Web: speak the countdown number via the Speech Synthesis API.
void speakRest(String text) {
  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;
    final u = html.SpeechSynthesisUtterance(text)
      ..rate = 1.1
      ..volume = 1.0
      ..pitch = 1.0;
    synth.speak(u);
  } catch (_) {}
}

String? _cached;

String _beepDataUrl() {
  if (_cached != null) return _cached!;
  const sampleRate = 8000;
  const durationSec = 0.45;
  final n = (sampleRate * durationSec).round();
  final b = BytesBuilder();
  void str(String s) => b.add(s.codeUnits);
  void u32(int v) => b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  void u16(int v) => b.add([v & 0xff, (v >> 8) & 0xff]);

  // WAV header: PCM, mono, 8-bit.
  str('RIFF'); u32(36 + n); str('WAVE');
  str('fmt '); u32(16); u16(1); u16(1);
  u32(sampleRate); u32(sampleRate); u16(1); u16(8);
  str('data'); u32(n);

  // Two-tone beep with a quick fade so it isn't clicky.
  for (var i = 0; i < n; i++) {
    final freq = i < n / 2 ? 880.0 : 1175.0;
    final env = (1.0 - (i % (n ~/ 2)) / (n / 2)).clamp(0.0, 1.0);
    final sample = (sin(2 * pi * freq * i / sampleRate) * 110 * env + 128)
        .round()
        .clamp(0, 255);
    b.addByte(sample);
  }
  _cached = 'data:audio/wav;base64,${base64Encode(b.toBytes())}';
  return _cached!;
}
