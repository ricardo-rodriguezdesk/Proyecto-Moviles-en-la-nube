import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

import '../../models/plan.dart';
import '../../providers/subscription_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/payment_service.dart';

enum CheckoutStep { form, authenticating, paying, done }

/// Estado del pago (sin setState).
class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required this.plan,
    required this.payments,
    required this.biometrics,
    required this.subscriptions,
    required String initialName,
  }) {
    name.text = initialName;
  }

  final Plan plan;
  final PaymentService payments;
  final BiometricService biometrics;
  final SubscriptionProvider subscriptions;

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final cardController = CardFormEditController();

  CheckoutStep _step = CheckoutStep.form;
  bool _cardComplete = false;
  String? _error;
  PaymentResult? _result;
  bool _disposed = false;

  CheckoutStep get step => _step;
  bool get cardComplete => _cardComplete;
  bool get busy =>
      _step == CheckoutStep.authenticating || _step == CheckoutStep.paying;
  String? get error => _error;
  PaymentResult? get result => _result;

  void onCardChanged(CardFieldInputDetails? details) {
    _cardComplete = details?.complete ?? false;
    _notify();
  }

  /// [confirmWithoutBiometrics] se llama si el dispositivo no tiene
  /// huella/PIN configurado: muestra un diálogo de confirmación normal.
  Future<void> pay({
    required String email,
    required Future<bool> Function() confirmWithoutBiometrics,
  }) async {
    if (busy) return;
    _error = null;
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!_cardComplete) {
      _error = 'Completa los datos de la tarjeta.';
      _notify();
      return;
    }

    // 1. Confirmación con el lector biométrico.
    _step = CheckoutStep.authenticating;
    _notify();
    final bio = await biometrics.confirm(
      'Confirma el pago de \$${plan.price.toStringAsFixed(0)} MXN '
      'del plan ${plan.name}',
    );
    if (bio == BiometricResult.failed) {
      _step = CheckoutStep.form;
      _error = 'No se confirmó tu identidad.';
      _notify();
      return;
    }
    if (bio == BiometricResult.unavailable && !await confirmWithoutBiometrics()) {
      _step = CheckoutStep.form;
      _notify();
      return;
    }

    // 2. Pago con Stripe.
    _step = CheckoutStep.paying;
    _notify();
    try {
      final result = await payments.pay(
        amountMxn: plan.price,
        description: 'Lumen · Plan ${plan.name} (mensual)',
        name: name.text.trim(),
        email: email,
      );
      // 3. Registrar la suscripción en Firestore.
      await subscriptions.activate(plan, result);
      _result = result;
      _step = CheckoutStep.done;
    } on PaymentException catch (e) {
      _error = e.message;
      _step = CheckoutStep.form;
    } catch (e) {
      debugPrint('[Checkout] Error al guardar la suscripción: $e');
      _error = 'No se pudo guardar tu suscripción. Intenta de nuevo.';
      _step = CheckoutStep.form;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    name.dispose();
    cardController.dispose();
    super.dispose();
  }
}
