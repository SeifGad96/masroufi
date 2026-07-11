// App-wide color constants — palette from PRD §8.2b
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Background / surface ──────────────────────────────────────────────────
  static const Color background     = Color(0xFF0F1117);
  static const Color surface        = Color(0xFF1A1D27);
  static const Color surfaceVariant = Color(0xFF242736);
  static const Color border         = Color(0xFF2E3247);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9399B2);
  static const Color textMuted     = Color(0xFF555B72);

  // ── Accent ───────────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFF6FA8DC); // sky blue
  static const Color accentLight   = Color(0xFF8FBFE8);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF8FC9A5);
  static const Color warning = Color(0xFFF6C453);
  static const Color error   = Color(0xFFF2726F);

  // ── Category palette (12 colors, PRD §8.2b) ──────────────────────────────
  static const List<Color> categoryPalette = [
    Color(0xFFF2726F), // 1  Coral red     — Food
    Color(0xFF4ECDC4), // 2  Teal          — Transportation
    Color(0xFFF6C453), // 3  Soft amber    — Bills
    Color(0xFF8FC9A5), // 4  Sage green    — Shopping
    Color(0xFF6FA8DC), // 5  Sky blue      — Entertainment
    Color(0xFFB39DDB), // 6  Soft purple   — Health
    Color(0xFFF5A462), // 7  Muted orange  — Other
    Color(0xFFA0E8CE), // 8  Mint          — (custom)
    Color(0xFFF1A7C1), // 9  Dusty pink    — (custom)
    Color(0xFF9FA8DA), // 10 Periwinkle    — (custom)
    Color(0xFFF0D678), // 11 Warm yellow   — (custom)
    Color(0xFF6FB3A8), // 12 Slate teal    — (custom)
  ];

  static Color categoryColor(int index) =>
      categoryPalette[index % categoryPalette.length];
}
