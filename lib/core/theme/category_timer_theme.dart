import 'package:flutter/material.dart';
import '../../models/measurement_model.dart';
import '../constants/app_colors.dart';

/// Central visual configuration for performance category timer cards.
/// Provides distinct color schemes, badges, and icons for Drink, Cake, and Order.
class CategoryTimerTheme {
  /// Primary vibrant accent color of this category
  final Color accent;

  /// Soft, light-tinted background color for the timer card
  final Color background;

  /// Distinct border color matching the category palette
  final Color border;

  /// Background color for category badge and icon container
  final Color badgeBg;

  /// Text and icon color for the category badge
  final Color badgeText;

  /// Background color for the central stopwatch box
  final Color stopwatchBg;

  /// Text color for the stopwatch digits during normal running
  final Color stopwatchText;

  /// Category icon
  final IconData icon;

  /// Vietnamese label (Nước, Bánh, Đơn hàng)
  final String label;

  const CategoryTimerTheme({
    required this.accent,
    required this.background,
    required this.border,
    required this.badgeBg,
    required this.badgeText,
    required this.stopwatchBg,
    required this.stopwatchText,
    required this.icon,
    required this.label,
  });

  /// Factory to get visual theme for a [PerformanceCategory].
  static CategoryTimerTheme of(PerformanceCategory category) {
    switch (category) {
      case PerformanceCategory.drink:
        return const CategoryTimerTheme(
          accent: AppColors.categoryDrink, // #E8192F Trạm Crimson Red
          background: Color(0xFFFFF7F7), // Delicate rose-white tint
          border: Color(0xFFFCA5A5), // Soft coral-red border
          badgeBg: Color(0xFFFEE2E2), // Pale red badge container
          badgeText: Color(0xFFB91C1C), // Deep crimson text
          stopwatchBg: Color(0xFFFFF0F0), // Stopwatch container bg
          stopwatchText: Color(0xFF991B1B), // Stopwatch digits
          icon: Icons.local_cafe_rounded,
          label: 'Nước',
        );

      case PerformanceCategory.cake:
        return const CategoryTimerTheme(
          accent: AppColors.categoryCake, // #D97706 Warm Amber Orange
          background: Color(0xFFFFFDF5), // Warm honey-cream tint
          border: Color(0xFFFCD34D), // Soft amber-gold border
          badgeBg: Color(0xFFFEF3C7), // Pale amber badge container
          badgeText: Color(0xFFB45309), // Deep amber text
          stopwatchBg: Color(0xFFFFFBEB), // Stopwatch container bg
          stopwatchText: Color(0xFF92400E), // Stopwatch digits
          icon: Icons.cake_rounded,
          label: 'Bánh',
        );

      case PerformanceCategory.order:
        return const CategoryTimerTheme(
          accent: AppColors.categoryOrder, // #1C4E6B Deep Slate Navy
          background: Color(0xFFF4F9FD), // Cool ice-blue tint
          border: Color(0xFF93C5FD), // Soft sky-navy border
          badgeBg: Color(0xFFE0F2FE), // Pale slate-blue badge container
          badgeText: Color(0xFF0369A1), // Deep navy text
          stopwatchBg: Color(0xFFEDF6FD), // Stopwatch container bg
          stopwatchText: Color(0xFF0C4A6E), // Stopwatch digits
          icon: Icons.receipt_long_rounded,
          label: 'Đơn hàng',
        );
    }
  }
}
