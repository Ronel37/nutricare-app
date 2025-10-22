import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryDark = Color(0xFF0A3D00);
  static const Color _primaryLight = Color(0xFF2E7D32);

  static const Color _secondaryDark = Color(0xFF1E88E5);
  static const Color _secondaryLight = Color(0xFF42A5F5);

  static const Color _backgroundDark = Colors.black;
  static const Color _backgroundLight = Color(0xFFF5F5F5);

  static const Color _cardDark =
      Color(0xFF121212); 
  static const Color _cardLight = Colors.white;

  static const Color _buttonDark = Color.fromARGB(255, 49, 46, 46);
  static const Color _addButtonDark = Color.fromARGB(255, 42, 116, 45);

  static const Color _textDark = Colors.white;
  static const Color _textLight = Colors.black87;
  static const Color _textDarkSecondary = Colors.white70;
  static const Color _textLightSecondary = Colors.black54;

  static const Map<String, Color> _bmiCategoryColorsDark = {
    'underweight': Color(0xFF1E88E5), 
    'normal': Color(0xFF4CAF50), 
    'overweight': Color(0xFFFF9800), 
    'obese': Color(0xFFF44336), 
  };

  static const Map<String, Color> _bmiCategoryBackgroundDark = {
    'underweight': Color(0xFF0D47A1), 
    'normal': Color(0xFF1B5E20), 
    'overweight': Color(0xFFE65100), 
    'obese': Color(0xFFB71C1C), 
  };

  static const Map<String, Color> _bmiCategoryColorsLight = {
    'underweight': Color(0xFF2196F3), 
    'normal': Color(0xFF4CAF50), 
    'overweight': Color(0xFFFF9800), 
    'obese': Color(0xFFF44336),
  };

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryLight,
      secondary: _secondaryLight,
      surface: _cardLight,
      surfaceTint: _primaryLight.withOpacity(0.05),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textLight,
    ),
    scaffoldBackgroundColor: _backgroundLight,
    textTheme: _getTextTheme(_textLight, _textLightSecondary),
    cardTheme: CardTheme(
      color: _cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
    ),
    iconTheme: const IconThemeData(
      color: _primaryLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _primaryLight,
      selectionColor: _primaryLight.withOpacity(0.25),
      selectionHandleColor: _primaryLight,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryLight, width: 2),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primaryDark,
      secondary: _secondaryDark,
      surface: _cardDark,
      surfaceTint: _primaryDark.withOpacity(0.05),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textDark,
    ),
    scaffoldBackgroundColor: _backgroundDark,
    textTheme: _getTextTheme(_textDark, _textDarkSecondary),
    cardTheme: CardTheme(
      color: Colors.grey.shade900, // Exact match from homepage
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _buttonDark, // Exact match from homepage
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white70,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _primaryDark,
      selectionColor: _primaryDark.withOpacity(0.25),
      selectionHandleColor: _primaryDark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryDark, width: 2),
      ),
    ),
  );

  // Helper method to get the text theme
  static TextTheme _getTextTheme(Color textColor, Color textSecondaryColor) {
    return TextTheme(
      displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      bodySmall: TextStyle(color: textSecondaryColor),
      labelLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: textColor),
      labelSmall: TextStyle(color: textSecondaryColor),
    );
  }

  // BMI Category Color Getters
  static Color getBmiCategoryColor(String category, {bool isDarkMode = true}) {
    final colorMap =
        isDarkMode ? _bmiCategoryColorsDark : _bmiCategoryColorsLight;
    return colorMap[category.toLowerCase()] ??
        (isDarkMode ? _primaryDark : _primaryLight);
  }

  // BMI Category Background Color Getters
  static Color getBmiCategoryBackgroundColor(String category) {
    return _bmiCategoryBackgroundDark[category.toLowerCase()] ?? _primaryDark;
  }

  // Gradient for background based on theme mode - matched with homepage
  static Gradient getBackgroundGradient(bool isDarkMode) {
    return isDarkMode
        ? const LinearGradient(
            colors: [
              Colors.black,
              _primaryDark, // Color(0xFF0A3D00)
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [
              _backgroundLight,
              Color(0xFFE8F5E9),
              _backgroundLight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
  }

  // Custom button styles
  static ButtonStyle getAddPersonButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _addButtonDark, // Color.fromARGB(255, 42, 116, 45)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: Colors.green,
          width: 1,
        ),
      ),
    );
  }

  // Get card icon opacity
  static double getCardIconOpacity() {
    return 0.2; // Used for card icons in homepage
  }
}
