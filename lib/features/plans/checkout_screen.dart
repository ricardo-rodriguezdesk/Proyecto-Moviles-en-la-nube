import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/plan.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/payment_service.dart';
import 'checkout_controller.dart';

/// Pantalla de pago: resumen del plan + formulario NATIVO de Stripe para
/// la tarjeta (valida número, fecha y CVC; los datos nunca pasan por
/// nuestro código) + confirmación con huella.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<CatalogProvider>().plans;
    final matches = plans.where((p) => p.id == planId);

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Plan no encontrado.')),
      );
    }

    if (!PaymentService.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pago')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Los pagos no están configurados.\n\nEjecuta la app con:\n'
              'flutter run --dart-define-from-file=stripe.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final user = context.read<SessionProvider>().user;
    return ChangeNotifierProvider(
      create: (ctx) => CheckoutController(
        plan: matches.first,
        payments: PaymentService(),
        biometrics: BiometricService(),
        subscriptions: ctx.read<SubscriptionProvider>(),
        initialName: user?.displayName ?? '',
      ),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    if (c.step == CheckoutStep.done) return _SuccessView(plan: c.plan);

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = context.read<SessionProvider>().user?.email ?? '';
    final plan = c.plan;

    Future<bool> confirmDialog() async {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.fingerprint),
              title: const Text('Confirmar pago'),
              content: Text(
                'Este dispositivo no tiene huella o PIN configurado.\n\n'
                '¿Confirmas el pago de \$${plan.price.toStringAsFixed(0)} MXN?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Pagar'),
                ),
              ],
            ),
          ) ??
          false;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: c.formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ---------- Resumen ----------
                Card(
                  margin: EdgeInsets.zero,
                  color: scheme.primaryContainer,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(Icons.local_florist,
                        color: scheme.primary, size: 36),
                    title: Text('Plan ${plan.name}', style: text.titleLarge),
                    subtitle: Text('${plan.plantsPerMonth} '
                        '${plan.plantsPerMonth == 1 ? 'planta' : 'plantas'} '
                        'al mes · se renueva cada mes'),
                    trailing: Text('\$${plan.price.toStringAsFixed(0)}',
                        style: text.headlineSmall),
                  ),
                ),
                const SizedBox(height: 24),

                // ---------- Titular ----------
                Text('Titular de la tarjeta', style: text.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: c.name,
                  enabled: !c.busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre como aparece en la tarjeta',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v ?? '').trim().length < 3
                      ? 'Escribe el nombre del titular'
                      : null,
                ),
                const SizedBox(height: 20),

                // ---------- Tarjeta (formulario nativo de Stripe) ----------
                Text('Datos de la tarjeta', style: text.titleMedium),
                const SizedBox(height: 8),
                CardFormField(
                  controller: c.cardController,
                  enablePostalCode: false,
                  countryCode: 'MX',
                  onCardChanged: c.onCardChanged,
                  style: CardFormStyle(
                    backgroundColor: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurface,
                    placeholderColor: scheme.onSurfaceVariant,
                    borderColor: scheme.outline,
                    borderRadius: 14,
                    fontSize: 16,
                    textErrorColor: scheme.error,
                    cursorColor: scheme.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        c.cardComplete ? Icons.check_circle : Icons.info_outline,
                        size: 16,
                        color: c.cardComplete
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.cardComplete
                              ? 'Tarjeta válida'
                              : 'Prueba con 4242 4242 4242 4242, fecha futura y '
                                  'cualquier CVC',
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                if (c.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    color: scheme.errorContainer,
                    child: ListTile(
                      leading: Icon(Icons.error_outline,
                          color: scheme.onErrorContainer),
                      title: Text(c.error!,
                          style: TextStyle(color: scheme.onErrorContainer)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: c.busy
                      ? null
                      : () => c.pay(
                            email: email,
                            confirmWithoutBiometrics: confirmDialog,
                          ),
                  icon: c.busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(switch (c.step) {
                    CheckoutStep.authenticating => 'Confirmando identidad…',
                    CheckoutStep.paying => 'Procesando pago…',
                    _ => 'Pagar \$${plan.price.toStringAsFixed(0)} MXN',
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      PaymentService.canCharge
                          ? 'Modo prueba de Stripe · no se cobra dinero real'
                          : 'Stripe valida tu tarjeta · pago simulado',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                if (isDark) const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final result = context.read<CheckoutController>().result;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.check, size: 56, color: scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('¡Bienvenido a ${plan.name}!',
                      textAlign: TextAlign.center, style: text.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Tu suscripción está activa. Pronto recibirás tus primeras '
                    'plantas.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge,
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    SelectableText(
                      'Referencia: ${result.id}',
                      textAlign: TextAlign.center,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => context.go('/profile'),
                    child: const Text('Ver mi plan'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Ir al inicio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
