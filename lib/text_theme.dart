import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// Custom Class for Light & Dark Text Themes
class STextTheme {
  STextTheme._(); // To avoid creating instances

  /// Customizable Light Text Theme
  static TextTheme lightAppTheme = const TextTheme(
    displayLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceDarkest),
    displayMedium: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceDarkest),
    displaySmall: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceDarkest),
    headlineLarge: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        color: SColors.onSurfaceDarkest),
    headlineMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        color: SColors.onSurfaceDarkest),
    headlineSmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: SColors.onSurfaceDarkest),
    titleLarge: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceDark),
    titleMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceDark),
    titleSmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceDark),
    bodyLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurface),
    bodyMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurface),
    bodySmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurface),
    labelLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceLight),
    labelMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: SColors.onSurfaceLight),
    labelSmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w300,
        color: SColors.onSurfaceLight),
  );

  /// Customizable Dark Text Theme
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: const TextStyle(
        fontSize: 32.0, fontWeight: FontWeight.bold, color: SColors.dark),
    displayMedium: const TextStyle(
        fontSize: 24.0, fontWeight: FontWeight.w600, color: SColors.dark),
    displaySmall: const TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: SColors.dark),
    headlineLarge: const TextStyle(
        fontSize: 32.0, fontWeight: FontWeight.bold, color: SColors.light),
    headlineMedium: const TextStyle(
        fontSize: 24.0, fontWeight: FontWeight.w600, color: SColors.light),
    headlineSmall: const TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: SColors.light),
    titleLarge: const TextStyle(
        fontSize: 16.0, fontWeight: FontWeight.w600, color: SColors.light),
    titleMedium: const TextStyle(
        fontSize: 16.0, fontWeight: FontWeight.w500, color: SColors.light),
    titleSmall: const TextStyle(
        fontSize: 16.0, fontWeight: FontWeight.w400, color: SColors.light),
    bodyLarge: const TextStyle(
        fontSize: 14.0, fontWeight: FontWeight.w500, color: SColors.light),
    bodyMedium: const TextStyle(
        fontSize: 14.0, fontWeight: FontWeight.normal, color: SColors.light),
    bodySmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: SColors.light.withValues(alpha: 0.5)),
    labelLarge: const TextStyle(
        fontSize: 12.0, fontWeight: FontWeight.normal, color: SColors.light),
    labelMedium: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        color: SColors.light.withValues(alpha: 0.5)),
    labelSmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        color: SColors.light.withValues(alpha: 0.5)),
  );
}
