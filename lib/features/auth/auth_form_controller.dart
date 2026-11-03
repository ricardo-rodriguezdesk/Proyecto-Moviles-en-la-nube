import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// Estado de los formularios de login, registro y recuperación.
/// Se crea uno por pantalla con ChangeNotifierProvider, así que
/// los TextEditingController se liberan solos al salir.
///
/// Todos los métodos devuelven null si salió bien, o el mensaje de error.
class AuthFormController extends ChangeNotifier {
  AuthFormController(this._service);

  final AuthService _service;

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _disposed = false;

  bool get obscure => _obscure;
  bool get loading => _loading;

  void toggleObscure() {
    _obscure = !_obscure;
    _notify();
  }

  bool validate() => formKey.currentState?.validate() ?? false;

  Future<String?> loginWithEmail() =>
      _run(() => _service.signInWithEmail(email.text, password.text));

  Future<String?> register() => _run(() => _service.registerWithEmail(
        name: name.text,
        email: email.text,
        password: password.text,
      ));

  Future<String?> sendPasswordReset() =>
      _run(() => _service.sendPasswordReset(email.text));

  Future<String?> loginWithGoogle() => _run(_service.signInWithGoogle);

  Future<String?> loginWithGithub() => _run(_service.signInWithGithub);

  Future<String?> _run(Future<void> Function() action) async {
    if (_loading) return null;
    _loading = true;
    _notify();
    try {
      await action();
      return null;
    } on FirebaseAuthException catch (e) {
      return AuthService.messageFor(e);
    } catch (_) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    } finally {
      _loading = false;
      _notify();
    }
  }

  // Si el login sale bien, el router cambia de pantalla y este controller
  // se destruye; por eso revisamos _disposed antes de notificar.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }
}
