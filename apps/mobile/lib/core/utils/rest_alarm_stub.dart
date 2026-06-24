import 'package:flutter/services.dart';

/// Non-web (mobile/desktop): use the platform alert sound + a haptic buzz.
void playRestAlarm() {
  try {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  } catch (_) {}
}

/// Spoken countdown — no-op off web (would need a TTS plugin on mobile); a light
/// tick haptic gives feedback instead.
void speakRest(String text) {
  try {
    HapticFeedback.selectionClick();
  } catch (_) {}
}

/// No audio-unlock needed off web.
void primeRestAudio() {}
