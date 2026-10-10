import 'package:flutter/material.dart';

/// Water-inspired blue/teal palette with large, elderly-friendly sizing.
class AppColors {
  static const deepBlue = Color(0xFF01579B);
  static const blue = Color(0xFF0288D1);
  static const teal = Color(0xFF00897B);
  static const aqua = Color(0xFF4DD0E1);
  static const background = Color(0xFFF1F8FB);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFEF6C00);
  static const danger = Color(0xFFC62828);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.teal,
      tertiary: AppColors.aqua,
      surface: Colors.white,
      error: AppColors.danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    // Bigger text everywhere for readability.
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.deepBlue),
      headlineSmall: base.textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.deepBlue),
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium
          ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.4),
      bodyMedium:
          base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
      labelLarge: base.textTheme.labelLarge
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.deepBlue,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: AppColors.deepBlue),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: text.labelLarge,
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: text.labelLarge,
          shape: rounded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: text.bodyLarge,
        helperMaxLines: 3,
        errorMaxLines: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.aqua.withValues(alpha: 0.35),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: AppColors.deepBlue,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 28,
            color: states.contains(WidgetState.selected)
                ? AppColors.deepBlue
                : AppColors.blue,
          ),
        ),
      ),
    );
  }
}
