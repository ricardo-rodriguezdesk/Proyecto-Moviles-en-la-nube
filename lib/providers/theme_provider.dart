import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maneja el tema claro/oscuro y lo guarda en el dispositivo.
/// Sin setState: la UI escucha este provider con context.watch.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) {
    final saved = _prefs.getString(_key);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  static const _key = 'theme_mode';
  final SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_key, mode.name);
  }

  Future<void> toggle(BuildContext context) =>
      setThemeMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
}
