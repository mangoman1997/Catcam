import 'package:flutter/material.dart';

/// 填貓相機顏色系統
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFFF9B7B);
  static const Color secondary = Color(0xFFFFB87B);
  static const Color accent = Color(0xFFFFD4A3);

  // Background Colors
  static const Color background = Color(0xFFFFF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF0EB);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F1419);
  static const Color textSecondary = Color(0xFF536471);
  static const Color textTertiary = Color(0xFF8B98A5);

  // Outline & Border
  static const Color outline = Color(0xFF2F3336);
  static const Color outlineLight = Color(0xFFE1E8ED);

  // Functional Colors
  static const Color error = Color(0xFFE02432);
  static const Color success = Color(0xFF00BA7C);
  static const Color warning = Color(0xFFFFAD1F);

  // Camera UI
  static const Color cameraBackground = Color(0xFF000000);
  static const Color shutterButton = Color(0xFFFFFFFF);
  static const Color shutterButtonRing = Color(0xFFFFFFFF);

  // Stencil Colors
  static const Color stencilBlack = Color(0xFF000000);
  static const Color stencilWhite = Color(0xFFFFFFFF);
  static const Color stencilPink = Color(0xFFFF6B9D);
  static const Color stencilBlue = Color(0xFF00D4FF);
  static const Color stencilPurple = Color(0xFF9B59B6);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overlayGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black54],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
