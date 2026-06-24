import 'package:flutter/services.dart';

/// Non-web (mobile/desktop): use the platform alert sound + a haptic buzz.
void playRestAlarm() {
  try {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  } catch (_) {}
}
