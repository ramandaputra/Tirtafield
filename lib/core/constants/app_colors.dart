import 'package:flutter/material.dart';

class AppColors {
  // Theme Palette from Tailwind Design Specification
  static const Color primary = Color(0xFF00288E);
  static const Color primaryContainer = Color(0xFF1E40AF);
  static const Color primaryFixed = Color(0xFFDDE1FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  static const Color secondary = Color(0xFF0051D5);
  static const Color secondaryContainer = Color(0xFF316BF3);
  static const Color secondaryFixed = Color(0xFFDBE1FF);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiaryContainer = Color(0xFF00563A);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color tertiaryFixedDim = Color(0xFF4EDEA3);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF059669);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);
  static const Color inverseSurface = Color(0xFF283044);
  static const Color inverseOnSurface = Color(0xFFEEF0FF);

  // Borders & Outlines
  static const Color outline = Color(0xFF757684);
  static const Color outlineVariant = Color(0xFFC4C5D5);
  static const Color cardBorder = Color(0xFFDAE2FD);

  // Text Colors
  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color danger = error;
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF001453);
  static const Color primaryLight = Color(0xFF1E40AF);

  // Role Identifiers
  static const Color roleKaryawan = Color(0xFF316BF3);
  static const Color roleDirektur = Color(0xFF7C3AED);
  static const Color roleStaffIT = Color(0xFF0D9488);

  // 4 Slot Presensi Accent Colors
  static const Color checkIn = Color(0xFF059669);
  static const Color breakOut = Color(0xFF316BF3);
  static const Color breakIn = Color(0xFF6366F1);
  static const Color checkOut = Color(0xFFEF4444);
}
