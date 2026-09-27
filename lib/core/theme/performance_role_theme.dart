import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Material defaults for the owner and manager areas. Status and category
/// colors remain independent of the current user's role.
class PerformanceRoleTheme {
  PerformanceRoleTheme._();

  static ThemeData owner(BuildContext context) => _build(
        context,
        AppColors.ownerAccent,
        AppColors.ownerSurface,
      );

  static ThemeData manager(BuildContext context) => _build(
        context,
        AppColors.managerAccent,
        AppColors.managerSurface,
      );

  static ThemeData _build(BuildContext context, Color accent, Color surface) {
    final base = Theme.of(context);
    final baseElevatedStyle =
        base.elevatedButtonTheme.style ?? const ButtonStyle();
    final baseOutlinedStyle =
        base.outlinedButtonTheme.style ?? const ButtonStyle();
    final baseTextStyle = base.textButtonTheme.style ?? const ButtonStyle();

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        onPrimary: Colors.white,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseElevatedStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? AppColors.textDisabled
                  : accent),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseOutlinedStyle.copyWith(
          foregroundColor: WidgetStatePropertyAll(accent),
          side: WidgetStatePropertyAll(BorderSide(color: accent, width: 1.5)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseTextStyle.copyWith(
          foregroundColor: WidgetStatePropertyAll(accent),
        ),
      ),
    );
  }
}
