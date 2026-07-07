import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Pulled directly from the Hikaya JO logo
  static const Color skyBlue = Color(0xFF89BEE0);      // sky / sun backdrop
  static const Color duneGold = Color(0xFFD9A866);      // Petra facade / desert dunes
  static const Color duneLight = Color(0xFFE8C793);     // lighter sand gradient
  static const Color teal = Color(0xFF4CAEA3);          // path & speech-bubble accent (JO wordmark)
  static const Color deepTeal = Color(0xFF1D6B6A);      // "Hikaya" wordmark — primary brand color
  static const Color amberStar = Color(0xFFD9A441);     // star accent

  // Neutrals (supporting the logo palette)
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF223838);
  static const Color textSecondary = Color(0xFF5F7574);

  // Semantic
  static const Color success = Color(0xFF4CAEA3);
  static const Color error = Color(0xFFC0604A);
  static const Color warning = Color(0xFFD9A441);
}