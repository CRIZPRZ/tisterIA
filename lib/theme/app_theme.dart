import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const bg = Color(0xFF0B0F0C);
  static const screenBg = Color(0xFF0E1310);
  static const card = Color(0xFF16211B);
  static const cardBorder = Color(0xFF223027);
  static const divider = Color(0xFF1B2620);

  /// Gradiente del header/hero (verde profundo).
  static const gradientStart = Color(0xFF12805A);
  static const gradientEnd = Color(0xFF0B3B2A);

  static const textWhite = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF8FA79A);
  static const textFaint = Color(0xFF6E7F75);
  static const textBody = Color(0xFFC9D3CD);
  static const navMuted = Color(0xFF6E7F75);

  /// Verde neón brillante — accento principal (%, iconos activos, CTAs, glow).
  static const green = Color(0xFF34F5A8);
  /// Verde sólido profundo — botones/superficies llenas (distinto del accento).
  static const greenSolid = Color(0xFF12805A);

  static const blue = Color(0xFF60A5FA);
  static const yellow = Color(0xFFEAB308);
  static const red = Color(0xFFFF5C5C);

  static const greenTint = Color(0x267CF0BE);
  static const blueTint = Color(0x1F60A5FA);
  static const redTint = Color(0x1FFF5C5C);
  static const greyTint = Color(0x268FA79A);
}

class AppText {
  AppText._();

  static TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textWhite,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.green,
      surface: AppColors.card,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
