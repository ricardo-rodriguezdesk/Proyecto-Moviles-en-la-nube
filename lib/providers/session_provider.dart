import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Estado global de la sesión. Lo escucha el router para decidir
/// si mostrar login, verificación de correo o la app.
///
/// (Se llama SessionProvider y no AuthProvider porque firebase_auth
/// ya tiene una clase AuthProvider y chocarían los nombres.)
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._service) : _user = _service.currentUser {
    _sub = _service.userChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthService _service;
  late final StreamSubscription<User?> _sub;
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// true si la cuenta se creó con correo y contraseña.
  bool get usesPassword =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;

  /// Solo las cuentas de correo necesitan verificar.
  /// (Google ya viene verificado; GitHub a veces no marca emailVerified.)
  bool get needsVerification =>
      isLoggedIn && usesPassword && !(_user!.emailVerified);

  /// Requisito: solo las cuentas de correo pueden cambiar su foto.
  bool get canEditPhoto => usesPassword;

  /// Vuelve a pedir el usuario a Firebase (p. ej. para saber si ya verificó).
  Future<void> reload() async {
    await _service.reloadUser();
    _user = _service.currentUser;
    notifyListeners();
  }

  Future<void> signOut() => _service.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
