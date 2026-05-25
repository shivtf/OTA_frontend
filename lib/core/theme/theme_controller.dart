import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier{
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;

  void toggleTheme(){
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setDark(){
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  void setLight(){
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  void setSystem(){
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}