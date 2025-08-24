import 'package:flutter/material.dart';

// Defines the color palette for the ExpensEase app based on the design mockups.
class AppColors {
  static const Color primaryBlue = Color(0xFF5B9DFF);
  static const Color primaryOrange = Color(0xFFFFA07A);

  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textWhite = Colors.white;

  static const Color green = Color(0xFF28a745);
  static const Color red = Color(0xFFdc3545);
  static const Color orange = Color(0xFFfd7e14);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}