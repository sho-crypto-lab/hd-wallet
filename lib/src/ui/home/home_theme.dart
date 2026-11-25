import 'package:flutter/material.dart';

/// ホーム専用の配色と文字階層。既存のBitcoin画面のテーマは変更しない。
ThemeData buildHomeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.black,
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF161616),
    onSurfaceVariant: const Color(0xFF686868),
    surfaceContainerLow: const Color(0xFFF4F4F4),
    outlineVariant: const Color(0xFFECECEC),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        height: 1.25,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        minimumSize: const Size(48, 88),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.onSurface,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: scheme.surfaceContainerLow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.38)
              : scheme.onSurface,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 0.5,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.onSurfaceVariant,
    ),
  );
}
