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

/// Web: "unlock" audio + speech by exercising them once from a user gesture, so
/// the later beep/voice (fired from a Timer) aren't blocked by autoplay policy.
void primeRestAudio() {
  try {
    final audio = html.AudioElement(_beepDataUrl())..volume = 0;
    audio.play();
    final synth = html.window.speechSynthesis;
    synth?.speak(html.SpeechSynthesisUtterance(' ')..volume = 0);
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
  const durationSec = 0.9; // longer so it's clearly heard after the voice
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

  // Three loud beeps (full amplitude) with short gaps — an unmistakable alarm.
  final beepLen = n ~/ 5; // 3 beeps + 2 gaps
  for (var i = 0; i < n; i++) {
    final cycle = i ~/ beepLen; // 0..4
    final inBeep = cycle.isEven; // beeps on 0,2,4
    if (!inBeep) { b.addByte(128); continue; }
    final t = i % beepLen;
    final env = (1.0 - t / beepLen).clamp(0.0, 1.0); // fade each beep
    final sample = (sin(2 * pi * 1000 * i / sampleRate) * 127 * env + 128)
        .round()
        .clamp(0, 255);
    b.addByte(sample);
  }
  _cached = 'data:audio/wav;base64,${base64Encode(b.toBytes())}';
  return _cached!;
}
