import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final val = prefs.get('theme_mode');
      if (val is String) {
        if (val == 'light') {
          state = ThemeMode.light;
        } else if (val == 'dark') {
          state = ThemeMode.dark;
        } else {
          state = ThemeMode.system;
        }
      } else {
        state = ThemeMode.system;
        await prefs.remove('theme_mode');
      }
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeStr = 'system';
    if (mode == ThemeMode.light) themeStr = 'light';
    if (mode == ThemeMode.dark) themeStr = 'dark';
    await prefs.setString('theme_mode', themeStr);
  }
}


