import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary =
      Color(0xFF7E2930); // Trạm brand maroon for shared UI
  static const Color primaryDark = Color(0xFF5C1F24);
  static const Color ownerAccent = Color(0xFF171717);
  static const Color ownerAccentDark = Color(0xFF050505);
  static const Color ownerSurface = Color(0xFFF7F7F5);
  static const Color ownerTint = Color(0xFFEDEBE6);
  static const Color managerAccent = Color(0xFF126CC3);
  static const Color managerAccentDark = Color(0xFF095AA8);
  static const Color managerSurface = Color(0xFFF7FAFE);
  static const Color managerTint = Color(0xFFE8F3FE);
  static const Color success = Color(0xFF1A6B5A); // Teal green
  static const Color accent = Color(0xFFEB9B28); // Orange/Yellow from logo
  static const Color info = Color(0xFF1C4E6B);
  static const Color neutral = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFF8F4EE);
  static const Color background = Color(0xFFF8F4EE);
  static const Color white = Colors.white;

  // Performance Category Colors
  static const Color categoryDrink = Color(0xFFE8192F); // Đỏ thương hiệu Trạm
  static const Color categoryCake = Color(0xFFD97706); // Cam hổ phách
  static const Color categoryOrder = Color(0xFF1C4E6B); // Xanh dương / Navy

  // Semantic Colors
  static const Color checkIn = success;
  static const Color checkOut = Color(0xFF888780);
  static const Color pending = accent;
  static const Color danger = Color(0xFFCB2D2E);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Colors.white;

  // Border & Divider
  static const Color border = Color(0xFFE0DAD4);
  static const Color divider = Color(0xFFECE8E2);

  // Card & Shadow
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x1A000000);

  // Status Colors
  static const Color statusActive = success;
  static const Color statusInactive = Color(0xFF888780);
  static const Color statusPending = accent;
  static const Color statusDanger = danger;

  // Role Badge Colors
  static const Color ownerBadge = ownerAccent;
  static const Color managerBadge = managerAccent;
  static const Color employeeBadge = Color(0xFF888780);

  // Shift Colors
  static const Color shiftMorning = Color(0xFFF5C842);
  static const Color shiftAfternoon = Color(0xFFFF8C42);
  static const Color shiftEvening = Color(0xFF1C4E6B);
  static const Color shiftOff = Color(0xFFCCCCCC);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22876D), Color(0xFF1A6B5A)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, surface],
    stops: [0.0, 0.45],
  );

  static const RadialGradient checkInButtonGradient = RadialGradient(
    colors: [Color(0xFF22876D), Color(0xFF1A6B5A)],
    radius: 0.85,
  );

  static const RadialGradient checkOutButtonGradient = RadialGradient(
    colors: [primary, primaryDark],
    radius: 0.85,
  );
}
