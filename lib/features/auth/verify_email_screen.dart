import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../services/auth_service.dart';
import 'widgets/auth_widgets.dart';

/// Estado de la pantalla de verificación: reenvío con espera de 60 s
/// (evita el error "too-many-requests") y comprobación manual.
class VerifyEmailController extends ChangeNotifier {
  VerifyEmailController(this._service, this._session);

  final AuthService _service;
  final SessionProvider _session;

  Timer? _timer;
  int _cooldown = 0;
  bool _sending = false;
  bool _checking = false;
  bool _disposed = false;

  int get cooldown => _cooldown;
  bool get sending => _sending;
  bool get checking => _checking;

  Future<String?> resend() async {
    if (_cooldown > 0 || _sending) return null;
    _sending = true;
    _notify();
    try {
      await _service.sendEmailVerification();
      _startCooldown();
      return 'Te enviamos otro correo de verificación.';
    } on FirebaseAuthException catch (e) {
      return AuthService.messageFor(e);
    } finally {
      _sending = false;
      _notify();
    }
  }

  /// Devuelve true si ya verificó (el router cambia de pantalla solo).
  Future<bool> check() async {
    _checking = true;
    _notify();
    try {
      await _session.reload();
    } catch (_) {
      // Sin internet, por ejemplo: simplemente no está verificado aún.
    }
    _checking = false;
    _notify();
    return !_session.needsVerification;
  }

  void _startCooldown() {
    _cooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _cooldown--;
      if (_cooldown <= 0) t.cancel();
      _notify();
    });
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

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => VerifyEmailController(
        ctx.read<AuthService>(),
        ctx.read<SessionProvider>(),
      ),
      child: const _VerifyView(),
    );
  }
}

class _VerifyView extends StatelessWidget {
  const _VerifyView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<VerifyEmailController>();
    final session = context.read<SessionProvider>();
    final email = session.user?.email ?? 'tu correo';

    Future<void> check() async {
      final messenger = ScaffoldMessenger.of(context);
      final verified = await c.check();
      if (!verified) {
        showMessage(messenger,
            'Aún no vemos la verificación. Abre el enlace del correo y vuelve a intentar.');
      }
    }

    Future<void> resend() async {
      final messenger = ScaffoldMessenger.of(context);
      showMessage(messenger, await c.resend());
    }

    return AuthScaffold(
      icon: Icons.mark_email_unread_outlined,
      title: 'Verifica tu correo',
      subtitle:
          'Enviamos un enlace a $email. Ábrelo para activar tu cuenta '
          '(revisa también la carpeta de spam).',
      children: [
        LoadingButton(
          label: 'Ya lo verifiqué',
          loading: c.checking,
          onPressed: check,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: (c.cooldown > 0 || c.sending) ? null : resend,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(c.cooldown > 0
              ? 'Reenviar correo (${c.cooldown} s)'
              : 'Reenviar correo'),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: session.signOut,
          child: const Text('Usar otra cuenta'),
        ),
      ],
    );
  }
}
