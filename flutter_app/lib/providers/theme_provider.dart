import 'package:flutter/material.dart';
import '../theme/pop_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    PopTheme.isDarkMode = _isDarkMode;
    notifyListeners();
  }
}
