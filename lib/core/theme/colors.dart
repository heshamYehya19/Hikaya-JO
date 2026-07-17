import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // -- Redesign (dark + gold) --
  // NOTE: names kept identical to the old palette on purpose — every screen
  // that already writes `AppColors.deepTeal`, `AppColors.teal`, etc. now
  // picks up the new look with zero changes to that screen's file.

  static const Color skyBlue = Color(0xFF89BEE0);       // unused in new design, kept for compat
  static const Color duneGold = Color(0xFFE8C787);       // secondary gold (icons, coin/star accents)
  static const Color duneLight = Color(0xFF2E2E33);      // was a light border — now dark-mode border
  static const Color teal = Color(0xFF4CC9B0);           // success / "done" / in-range accent
  static const Color deepTeal = Color(0xFFD4A857);       // was brand-primary teal — now brand-primary gold
  static const Color amberStar = Color(0xFFD4A857);      // star accent — matches primary gold

  // Neutrals — now dark surface instead of light
  static const Color background = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF17171A);
  static const Color textPrimary = Color(0xFFF5F1E8);
  static const Color textSecondary = Color(0xFFA3A0A0);

  // Semantic
  static const Color success = Color(0xFF4CC9B0);
  static const Color error = Color(0xFFE0645B);
  static const Color warning = Color(0xFFD4A857);

  // New tokens used only by the redesign's card gradients / elevated surfaces
  static const Color surfaceElevated = Color(0xFF1F1F23);
}