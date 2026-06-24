// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

// One persistent element, unlocked on a user gesture and reused for the beep —
// browsers block a fresh element.play() fired from a Timer.
html.AudioElement? _alarmEl;
html.AudioElement? _sirenEl;

/// Web: start a looping siren (overtime alarm). Reuses a persistent element so
/// it stays unlocked.
void startRestSiren() {
  try {
    final el = _sirenEl ??= html.AudioElement(_sirenDataUrl())..loop = true;
    el
      ..loop = true
      ..volume = 1.0
      ..currentTime = 0;
    el.play();
  } catch (_) {}
}

/// Web: stop the looping siren.
void stopRestSiren() {
  try {
    _sirenEl?.pause();
    _sirenEl?.currentTime = 0;
  } catch (_) {}
}

/// Web: replay the (already-unlocked) beep element, and also speak a cue — the
/// speech channel is reliably unlocked, guaranteeing audible end-of-rest feedback.
void playRestAlarm() {
  try {
    final synth = html.window.speechSynthesis;
    // Drop any queued numbers so "Rest over" speaks immediately, not after them.
    synth?.cancel();
    synth?.speak(html.SpeechSynthesisUtterance('Rest over')
      ..volume = 1.0
      ..rate = 1.0);
  } catch (_) {}
  try {
    final el = _alarmEl ??= html.AudioElement(_beepDataUrl());
    el
      ..volume = 1.0
      ..currentTime = 0;
    el.play();
  } catch (_) {}
}

/// Web: "unlock" audio + speech by exercising them once from a user gesture, so
/// the later beep/voice (fired from a Timer) aren't blocked by autoplay policy.
void primeRestAudio() {
  try {
    final el = _alarmEl ??= html.AudioElement(_beepDataUrl());
    el.muted = true;
    // After the muted play unlocks it, reset so it's ready to beep audibly later.
    el.play().then((_) {
      el
        ..pause()
        ..muted = false
        ..currentTime = 0;
    }).catchError((_) {});
    // Unlock the siren element too.
    final siren = _sirenEl ??= html.AudioElement(_sirenDataUrl())..loop = true;
    siren.muted = true;
    siren.play().then((_) {
      siren
        ..pause()
        ..muted = false
        ..currentTime = 0;
    }).catchError((_) {});
    final synth = html.window.speechSynthesis;
    synth?.speak(html.SpeechSynthesisUtterance(' ')..volume = 0);
  } catch (_) {}
}

String? _sirenCache;

/// A ~1s wailing siren (frequency sweeps up and down), looped by the element.
String _sirenDataUrl() {
  if (_sirenCache != null) return _sirenCache!;
  const sampleRate = 8000;
  const durationSec = 1.0;
  final n = (sampleRate * durationSec).round();
  final b = BytesBuilder();
  void str(String s) => b.add(s.codeUnits);
  void u32(int v) => b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  void u16(int v) => b.add([v & 0xff, (v >> 8) & 0xff]);
  str('RIFF'); u32(36 + n); str('WAVE');
  str('fmt '); u32(16); u16(1); u16(1);
  u32(sampleRate); u32(sampleRate); u16(1); u16(8);
  str('data'); u32(n);

  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    // Sweep 600 <-> 1200 Hz over the second for a wail.
    final sweep = (i / n) * 2 * pi;
    final freq = 900 + 300 * sin(sweep * 2);
    phase += 2 * pi * freq / sampleRate;
    final sample = (sin(phase) * 127 + 128).round().clamp(0, 255);
    b.addByte(sample);
  }
  _sirenCache = 'data:audio/wav;base64,${base64Encode(b.toBytes())}';
  return _sirenCache!;
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
