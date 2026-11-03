import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import 'auth_form_controller.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthFormController(ctx.read<AuthService>()),
      child: const _ForgotView(),
    );
  }
}

class _ForgotView extends StatelessWidget {
  const _ForgotView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AuthFormController>();

    Future<void> submit() async {
      if (!c.validate()) return;
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      final sentTo = c.email.text.trim();
      final error = await c.sendPasswordReset();
      if (error != null) {
        showMessage(messenger, error);
        return;
      }
      showMessage(
        messenger,
        'Si $sentTo tiene cuenta, te enviamos un enlace para cambiar tu contraseña.',
      );
      router.pop();
    }

    return AuthScaffold(
      showBack: true,
      icon: Icons.key_outlined,
      title: 'Recupera tu contraseña',
      subtitle: 'Escribe tu correo y te mandamos un enlace para crear una nueva',
      children: [
        Form(
          key: c.formKey,
          child: TextFormField(
            controller: c.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => submit(),
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          label: 'Enviar enlace',
          loading: c.loading,
          onPressed: submit,
        ),
      ],
    );
  }
}
