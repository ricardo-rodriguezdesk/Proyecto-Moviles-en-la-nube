import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import 'auth_form_controller.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthFormController(ctx.read<AuthService>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AuthFormController>();

    // Si el registro sale bien, el router manda solo a /verify.
    Future<void> submit() async {
      if (!c.validate()) return;
      final messenger = ScaffoldMessenger.of(context);
      showMessage(messenger, await c.register());
    }

    return AuthScaffold(
      showBack: true,
      icon: Icons.person_add_alt_1_outlined,
      title: 'Crea tu cuenta',
      subtitle: 'Te enviaremos un correo para verificarla',
      children: [
        Form(
          key: c.formKey,
          child: Column(
            children: [
              TextFormField(
                controller: c.name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: Validators.name,
              ),
              const SizedBox(height: 16),
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
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: c.confirm,
                obscureText: c.obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: Validators.confirm(() => c.password.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          label: 'Crear cuenta',
          loading: c.loading,
          onPressed: submit,
        ),
      ],
    );
  }
}
