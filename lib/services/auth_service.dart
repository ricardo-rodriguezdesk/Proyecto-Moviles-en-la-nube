import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// ID de cliente WEB de Firebase (oauth_client tipo 3 en
  /// google-services.json). Lo pide Google para emitir el idToken.
  static const _googleWebClientId =
      '836658534715-4saivlg6trrs94ag1bcrlckbsvd7v1f8.apps.googleusercontent.com';
  bool _googleReady = false;

  /// Inicio de sesión con Google usando la ventana NATIVA de cuentas de
  /// Android (Credential Manager), sin abrir el navegador.
  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(serverClientId: _googleWebClientId);
      _googleReady = true;
    }
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
            code: 'invalid-credential', message: 'Google no devolvió el token.');
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(code: 'canceled');
      }
      throw FirebaseAuthException(
        code: 'google-sign-in',
        message: 'No se pudo iniciar sesión con Google (${e.code.name}).',
      );
    }
  }

  /// GitHub por código (Device Flow): con el token que entrega GitHub se
  /// inicia sesión en Firebase. Ver features/auth/github_device_flow.dart.
  Future<void> signInWithGithubToken(String accessToken) async {
    await _auth.signInWithCredential(
      GithubAuthProvider.credential(accessToken),
    );
  }

  Future<void> signInWithGithub() async {
    final provider = GithubAuthProvider()..addScope('read:user');
    await _auth.signInWithProvider(provider);
  }

  Future<void> signOut() async {
    // También se cierra la sesión de Google para poder elegir otra cuenta.
    try {
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

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
