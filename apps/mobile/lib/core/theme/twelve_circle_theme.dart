// ═══════════════════════════════════════════════════════════════════════════
// 12 CIRCLE THEME · Tier 3 — the brand bundle  (PRODUCT-SPECIFIC)
//
// The ONLY place raw brand values live. It ASSIGNS the Helix semantic contract
// from 12 Circle's primitives + choices, then hands off to the brand-agnostic
// HelixThemeBuilder. Swap this file → different product; Helix is untouched.
//
// Personality (athletic consumer-wellness — WHOOP / Strava / Nike / Levels /
// Apple Fitness+ — NOT enterprise or medical):
//   • Color   — high-contrast, energetic; white metric readouts on deep neutral
//   • Type    — Outfit (rounded, energetic display) · Inter (UI/body) ·
//               Rajdhani (condensed athletic numerics for big metric displays)
//   • Motion  — springy, celebratory, momentum-driven (spring curve, punchy)
//   • Density — airy, rounded, consumer-grade (28px cards, pill CTAs)
//   • Voice   — motivational, athletic
// ═══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../helix/helix_primitives.dart';
import '../helix/helix_semantics.dart';
import '../helix/helix_theme_builder.dart';

/// 12 Circle brand primitives — product hex. Nothing outside this file should
/// reference these directly; components read semantic tokens (context.helix.*).
class _Brand {
  // Deep, cool neutral base — lets vivid accents + white metrics pop.
  static const bg          = Color(0xFF0A0C10);
  static const surface     = Color(0xFF14171D);
  static const surfaceHigh = Color(0xFF1D222B);
  static const surfaceSunken = Color(0xFF07090C);
  static const border      = Color(0x1FFFFFFF); // white ~12% — airy hairline

  static const white  = Color(0xFFFFFFFF);       // max-contrast metric readouts
  static const grey   = Color(0xFF9AA3AF);
  static const greyDim = Color(0xFF5B646F);

  static const electric = Color(0xFF7C5CFF);     // energetic accent (12C violet, vivid)
  static const electricMuted = Color(0x337C5CFF);
  static const mint   = Color(0xFF2FE0A6);       // celebratory positive
  static const amber  = Color(0xFFFFB020);
  static const coral  = Color(0xFFFF4D6A);       // vivid, athletic alert
}

class TwelveCircleTheme {
  static const String voice = 'motivational · athletic · in-your-corner';

  /// The semantic assignment — 12 Circle's answer to the Helix contract.
  static const HelixSemantics semantics = HelixSemantics(
    background: _Brand.bg, surface: _Brand.surface, surfaceHigh: _Brand.surfaceHigh,
    surfaceSunken: _Brand.surfaceSunken, border: _Brand.border,
    textPrimary: _Brand.white, textSecondary: _Brand.grey, textTertiary: _Brand.greyDim,
    accent: _Brand.electric, accentFg: _Brand.white, accentMuted: _Brand.electricMuted,
    success: _Brand.mint, warning: _Brand.amber, danger: _Brand.coral, dangerFg: _Brand.white,
    // Density/radius — airy, rounded, consumer-grade.
    radiusCard: HelixRadius.xxl, radiusButton: HelixRadius.pill, radiusField: HelixRadius.lg,
    // Motion — springy, celebratory, momentum-driven.
    easeBrand: HelixMotion.spring, durationBrand: HelixMotion.d300,
    // Type — energetic display, clean body, condensed athletic numerics.
    fontDisplay: 'Outfit', fontBody: 'Inter', fontNumeric: 'Rajdhani',
  );

  static ThemeData get theme => HelixThemeBuilder.dark(semantics);
}
