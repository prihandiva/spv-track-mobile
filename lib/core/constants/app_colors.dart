import 'package:flutter/material.dart';

class AppColors {
  // Brand Deep Slate & Executive Navy
  static const Color brandDark = Color(0xFF0A1128);
  static const Color brandNavy = Color(0xFF132B4F);
  static const Color brandBlue = Color(0xFF1E3A8A);
  static const Color brandAzure = Color(0xFF2563EB);
  static const Color brandTeal = Color(0xFF064E3B);
  static const Color brandTealLight = Color(0xFF0D5950);

  // Vibrant Accents
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentEmeraldDark = Color(0xFF059669);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentSky = Color(0xFF0EA5E9);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberDark = Color(0xFFD97706);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentRed = Color(0xFFEF4444);

  // Status Tints & Badges
  static const Color statusSubmitted = Color(0xFF059669);
  static const Color statusSubmittedBg = Color(0xFFECFDF5);
  static const Color statusSubmittedBorder = Color(0xFFA7F3D0);

  static const Color statusDraft = Color(0xFFD97706);
  static const Color statusDraftBg = Color(0xFFFFFBEB);
  static const Color statusDraftBorder = Color(0xFFFDE68A);

  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  // Neutral Background & Surface
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocus = Color(0xFF2563EB);

  // High Contrast Modern Typography
  static const Color textHeading = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Executive Gradients
  static const LinearGradient executiveGradient = LinearGradient(
    colors: [
      Color(0xFF0F172A),
      Color(0xFF132B4F),
      Color(0xFF1E3A8A),
      Color(0xFF0D5950),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [
      Color(0xFF132B4F),
      Color(0xFF1E40AF),
      Color(0xFF0D5950),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Layered BoxShadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevateShadow => [
    BoxShadow(
      color: const Color(0xFF132B4F).withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
