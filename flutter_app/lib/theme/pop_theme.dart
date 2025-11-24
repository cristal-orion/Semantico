import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PopTheme {
  static bool isDarkMode = false;

  // Colori Pop (Dynamic)
  // Colori Pop (Dynamic)
  static Color get yellow =>
      isDarkMode ? const Color(0xFFFBC02D) : const Color(0xFFFFEB3B); // Darker Yellow
  static Color get cyan =>
      isDarkMode ? const Color(0xFF0097A7) : const Color(0xFF00BCD4); // Darker Cyan
  static Color get magenta =>
      isDarkMode ? const Color(0xFFC2185B) : const Color(0xFFE91E63); // Darker Pink
  
  static Color get orange =>
      isDarkMode ? const Color(0xFFE65100) : const Color(0xFFFF9800);
  static Color get blue =>
      isDarkMode ? const Color(0xFF1565C0) : const Color(0xFF2196F3);
  static Color get green =>
      isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50);
  static Color get red =>
      isDarkMode ? const Color(0xFFC62828) : const Color(0xFFF44336);
  static Color get grey =>
      isDarkMode ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
  
  // In Dark Mode, Black becomes White (for text/borders) and White becomes Black (for background)
  // In Dark Mode, Black becomes White (for text/borders) and White becomes Black (for background)
  static Color get black => isDarkMode ? const Color(0xFFE0E0E0) : Colors.black; // Off-white text
  static Color get white => isDarkMode ? const Color(0xFF121212) : Colors.white; // Dark background
  static Color get offWhite =>
      isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF8F8F8);

  // Bordi
  static Border get border => Border.all(color: black, width: 3);
  static BorderRadius radius = BorderRadius.circular(12);

  // Ombre Hard
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: black,
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ];

  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: black,
          offset: const Offset(2, 2),
          blurRadius: 0,
        ),
      ];

  // Decorazioni
  static BoxDecoration boxDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? white,
      border: border,
      borderRadius: radius,
      boxShadow: shadow,
    );
  }

  // Testi
  static TextStyle get titleStyle => GoogleFonts.fredoka(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: black,
        letterSpacing: 1.0,
      );

  static TextStyle get headingStyle => titleStyle;

  static TextStyle get bodyStyle => GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: black,
      );
}
