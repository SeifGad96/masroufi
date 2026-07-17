
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  
  static const Color background     = Color(0xFF0F1117);
  static const Color surface        = Color(0xFF1A1D27);
  static const Color surfaceVariant = Color(0xFF242736);
  static const Color border         = Color(0xFF2E3247);

  
  static const Color textPrimary   = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9399B2);
  static const Color textMuted     = Color(0xFF555B72);

  
  static const Color accent        = Color(0xFF6FA8DC); 
  static const Color accentLight   = Color(0xFF8FBFE8);

  
  static const Color success = Color(0xFF8FC9A5);
  static const Color warning = Color(0xFFF6C453);
  static const Color error   = Color(0xFFF2726F);

  
  static const List<Color> categoryPalette = [
    Color(0xFFF2726F), 
    Color(0xFF4ECDC4), 
    Color(0xFFF6C453), 
    Color(0xFF8FC9A5), 
    Color(0xFF6FA8DC), 
    Color(0xFFB39DDB), 
    Color(0xFFF5A462), 
    Color(0xFFA0E8CE), 
    Color(0xFFF1A7C1), 
    Color(0xFF9FA8DA), 
    Color(0xFFF0D678), 
    Color(0xFF6FB3A8), 
  ];

  static Color categoryColor(int index) =>
      categoryPalette[index % categoryPalette.length];
}
