import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Primary brand — Teal
  // ---------------------------------------------------------------------------
  static const Color tealPrimary = Color(0xFF1A7A8A);
  static const Color tealLight   = Color(0xFF2A9BAD);
  static const Color tealDark    = Color(0xFF0F5A68);

  // ---------------------------------------------------------------------------
  // Accent — Orange (CTAs, active tabs, badges)
  // ---------------------------------------------------------------------------
  static const Color orangeAccent = Color(0xFFFF6B2B);
  static const Color orangeLight  = Color(0xFFFF8C4A);

  // ---------------------------------------------------------------------------
  // Blue accent (skip/next controls, secondary actions)
  // ---------------------------------------------------------------------------
  static const Color blueAccent = Color(0xFF4FC3F7);

  // ---------------------------------------------------------------------------
  // Neutral / Surface
  // ---------------------------------------------------------------------------
  static const Color background      = Color(0xFFF5F7FA);
  static const Color surfaceCard     = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF0F2F5);
  static const Color divider         = Color(0xFFE0E4EA);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------
  static const Color textPrimary   = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Semantic / Status
  // ---------------------------------------------------------------------------
  static const Color statusOnline  = Color(0xFF2ECC71);
  static const Color statusWarning = Color(0xFFF39C12);
  static const Color statusOffline = Color(0xFFE74C3C);
  static const Color statusUnknown = Color(0xFF95A5A6);

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------
  static const Color validationOk    = Color(0xFF27AE60);
  static const Color validationError = Color(0xFFE74C3C);

  // ---------------------------------------------------------------------------
  // Dark mode surface overrides
  // Updated to match the v2 design system — cinematic near-black palette.
  // ---------------------------------------------------------------------------
  static const Color backgroundDark      = Color(0xFF0A0E14); // page — near-black
  static const Color surfaceCardDark     = Color(0xFF131923); // card surface
  static const Color surfaceElevatedDark = Color(0xFF1C2535); // elevated card / inset grouped
  static const Color chromeDark          = Color(0xFF0F1520); // nav bar / tab bar
  static const Color borderDark          = Color(0x12FFFFFF); // 7% white divider
  static const Color textPrimaryDark     = Color(0xFFF0F4F8);
  static const Color textSecondaryDark   = Color(0xFF8A9BB0);
  static const Color textTertiaryDark    = Color(0xFF5A6A7D);

  // Status glow helpers — used for status dots with box-shadow glow effect.
  static const Color statusOnlineGlow  = Color(0x552ECC71);
  static const Color statusWarningGlow = Color(0x55F39C12);
  static const Color statusOfflineGlow = Color(0x55E74C3C);
}
