import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda si el usuario ya vio el onboarding (solo se muestra una vez).
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider(this._prefs) : _seen = _prefs.getBool(_key) ?? false;

  static const _key = 'onboarding_seen';
  final SharedPreferences _prefs;
  bool _seen;

  bool get seen => _seen;

  Future<void> finish() async {
    _seen = true;
    notifyListeners();
    await _prefs.setBool(_key, true);
  }

  /// Útil para probar: vuelve a mostrar el onboarding.
  Future<void> reset() async {
    _seen = false;
    notifyListeners();
    await _prefs.setBool(_key, false);
  }
}
