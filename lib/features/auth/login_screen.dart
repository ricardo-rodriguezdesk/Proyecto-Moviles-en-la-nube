import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import 'auth_form_controller.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthFormController(ctx.read<AuthService>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AuthFormController>();

    Future<void> submitEmail() async {
      if (!c.validate()) return;
      final messenger = ScaffoldMessenger.of(context);
      showMessage(messenger, await c.loginWithEmail());
    }

    Future<void> submitSocial(Future<String?> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      showMessage(messenger, await action());
    }

    return AuthScaffold(
      title: 'Bienvenido a Lumen',
      subtitle: 'Inicia sesión para cuidar tus plantas',
      children: [
        Form(
          key: c.formKey,
          child: Column(
            children: [
              TextFormField(
                controller: c.email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: c.password,
                obscureText: c.obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => submitEmail(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        c.obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: c.toggleObscure,
                  ),
                ),
                validator: Validators.password,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot'),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        const SizedBox(height: 8),
        LoadingButton(
          label: 'Entrar',
          loading: c.loading,
          onPressed: submitEmail,
        ),
        const SizedBox(height: 28),
        const TextDivider('o continúa con'),
        const SizedBox(height: 20),
        SocialButton(
          icon: FontAwesomeIcons.google,
          label: 'Continuar con Google',
          onPressed: c.loading ? null : () => submitSocial(c.loginWithGoogle),
        ),
        const SizedBox(height: 12),
        SocialButton(
          icon: FontAwesomeIcons.github,
          label: 'Continuar con GitHub',
          onPressed: c.loading ? null : () => submitSocial(c.loginWithGithub),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿No tienes cuenta?'),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ],
    );
  }
}
