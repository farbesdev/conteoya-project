import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// Provider global del modo de tema. Persiste en SharedPreferences.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadFromPrefs();
  }

  /// Carga el tema guardado al iniciar la app de forma segura.
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (stored == 'light') {
        state = ThemeMode.light;
      } else if (stored == 'dark') {
        state = ThemeMode.dark;
      }
    } catch (_) {
      // Ignorar cualquier fallo en SharedPreferences en el inicio
    }
  }

  /// Alterna entre claro y oscuro y persiste la selección.
  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, state == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  /// Establece un modo específico.
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  bool get isDark => state == ThemeMode.dark;
}
