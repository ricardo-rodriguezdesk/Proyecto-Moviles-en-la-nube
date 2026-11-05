import 'package:firebase_auth/firebase_auth.dart';

/// Toda la comunicación con Firebase Authentication pasa por aquí.
/// Las pantallas nunca llaman a FirebaseAuth directamente.
class AuthService {
  AuthService() {
    // Los correos de verificación y recuperación llegan en español.
    _auth.setLanguageCode('es');
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Emite cuando el usuario inicia/cierra sesión o cambia su perfil
  /// (nombre, foto). Lo usa SessionProvider.
  Stream<User?> get userChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  // ---------- Correo y contraseña ----------

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await cred.user?.sendEmailVerification();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ---------- Proveedores externos ----------

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    await _auth.signInWithProvider(provider);
  }

  Future<void> signInWithGithub() async {
    final provider = GithubAuthProvider()..addScope('read:user');
    await _auth.signInWithProvider(provider);
  }

  Future<void> signOut() => _auth.signOut();

  // ---------- Perfil ----------
  // Al cambiar el nombre o la foto, userChanges() emite y SessionProvider
  // avisa a todas las pantallas (inicio, perfil...) para que se actualicen.

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  Future<void> updatePhotoUrl(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
  }

  // ---------- Mensajes de error en español ----------

  /// Devuelve null cuando el usuario canceló (no hay nada que mostrar).
  static String? messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      case 'account-exists-with-different-credential':
        return 'Ese correo ya está registrado con otro método de inicio de sesión.';
      case 'web-context-canceled':
      case 'web-context-cancelled':
      case 'canceled':
      case 'cancelled':
        return null;
      default:
        return e.message ?? 'Ocurrió un error (${e.code}).';
    }
  }
}
