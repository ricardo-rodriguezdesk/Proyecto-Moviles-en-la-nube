import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';

/// Inicio de sesión con GitHub por "Device Flow" (el método de las apps de
/// TV): la app muestra un código, el usuario lo escribe en
/// github.com/login/device desde cualquier navegador, y la app recibe el
/// token sin abrir una pestaña web dentro del celular.
///
/// Con el token se inicia sesión en Firebase con
/// GithubAuthProvider.credential (no se necesita el secreto del cliente).
class GithubDeviceFlowController extends ChangeNotifier {
  GithubDeviceFlowController(this._auth) {
    _start();
  }

  /// Client ID de la OAuth App de GitHub (es público, no es un secreto).
  static const _clientId = 'Ov23liTzH3VX4RDQ2k0h';

  final AuthService _auth;
  Timer? _timer;
  bool _disposed = false;

  String? _userCode;
  String _verificationUri = 'https://github.com/login/device';
  String? _deviceCode;
  int _interval = 5;
  String? _error;
  bool _done = false;

  String? get userCode => _userCode;
  String get verificationUri => _verificationUri;
  String? get error => _error;
  bool get done => _done;
  bool get loading => _userCode == null && _error == null;

  Future<void> _start() async {
    try {
      final res = await http.post(
        Uri.parse('https://github.com/login/device/code'),
        headers: {'Accept': 'application/json'},
        body: {'client_id': _clientId, 'scope': 'read:user user:email'},
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || body['device_code'] == null) {
        _fail(body['error'] == 'device_flow_disabled'
            ? 'Activa "Enable Device Flow" en la OAuth App de GitHub.'
            : 'GitHub no respondió (${body['error'] ?? res.statusCode}).');
        return;
      }
      _deviceCode = body['device_code'] as String;
      _userCode = body['user_code'] as String;
      _verificationUri =
          body['verification_uri'] as String? ?? _verificationUri;
      _interval = (body['interval'] as num?)?.toInt() ?? 5;
      _notify();
      _schedulePoll();
    } catch (e) {
      _fail('Sin conexión con GitHub. Revisa tu internet.');
    }
  }

  void _schedulePoll() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: _interval), _poll);
  }

  Future<void> _poll() async {
    if (_disposed || _deviceCode == null) return;
    try {
      final res = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': _clientId,
          'device_code': _deviceCode!,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;

      if (token != null) {
        await _auth.signInWithGithubToken(token);
        _done = true; // el router cambia de pantalla solo
        _notify();
        return;
      }
      switch (body['error']) {
        case 'authorization_pending':
          _schedulePoll();
        case 'slow_down':
          _interval += 5;
          _schedulePoll();
        case 'expired_token':
          _fail('El código expiró. Cierra y vuelve a intentarlo.');
        case 'access_denied':
          _fail('Cancelaste la autorización en GitHub.');
        default:
          _fail('GitHub rechazó la solicitud (${body['error']}).');
      }
    } on FirebaseAuthException catch (e) {
      _fail(AuthService.messageFor(e) ?? 'No se pudo iniciar sesión.');
    } catch (_) {
      // Un fallo de red momentáneo: se vuelve a intentar.
      _schedulePoll();
    }
  }

  Future<void> openGithub() async {
    try {
      await launchUrl(Uri.parse(_verificationUri),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _fail(String message) {
    _error = message;
    _timer?.cancel();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// Abre el diálogo con el código de GitHub.
Future<void> showGithubDeviceFlow(BuildContext context) {
  final auth = context.read<AuthService>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => GithubDeviceFlowController(auth),
      child: const _GithubDeviceDialog(),
    ),
  );
}

class _GithubDeviceDialog extends StatelessWidget {
  const _GithubDeviceDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GithubDeviceFlowController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // Al iniciar sesión, el diálogo se cierra solo.
    if (c.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }

    return AlertDialog(
      icon: const Icon(Icons.code),
      title: const Text('Continuar con GitHub'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.error != null)
              Text(c.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error))
            else if (c.loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else ...[
              Text(
                'Abre github.com/login/device en cualquier navegador '
                '(tu computadora o tu celular) y escribe este código:',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: c.userCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    c.userCode!,
                    style: text.headlineMedium?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Toca el código para copiarlo', style: text.bodySmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text('Esperando autorización…', style: text.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (c.userCode != null && c.error == null)
          FilledButton(
            onPressed: c.openGithub,
            child: const Text('Abrir GitHub'),
          ),
      ],
    );
  }
}
