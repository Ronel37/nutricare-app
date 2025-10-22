import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String THEME_KEY = 'theme_preference';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemePreference();
  }

  void _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(THEME_KEY);
    
    if (themeValue == null) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = themeValue == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      THEME_KEY, 
      mode == ThemeMode.dark ? 'dark' : 'light'
    );
    
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light);
  }
}