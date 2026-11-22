import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;

/// Llaves de Stripe en MODO PRUEBA. Se pasan al compilar desde stripe.json
/// (que NO se sube a GitHub):
///   flutter run --dart-define-from-file=stripe.json
const _publishableKey = String.fromEnvironment('STRIPE_PK');
const _secretKey = String.fromEnvironment('STRIPE_SK');

/// Resultado de un pago.
class PaymentResult {
  const PaymentResult({
    required this.id,
    required this.mode,
    this.last4,
    this.brand,
  });

  /// ID de Stripe: PaymentIntent (pi_...) o PaymentMethod (pm_...).
  final String id;

  /// 'payment_intent' = cobro de prueba completo en Stripe.
  /// 'payment_method' = Stripe validó la tarjeta; el cobro se simula.
  final String mode;
  final String? last4;
  final String? brand;
}

class PaymentException implements Exception {
  PaymentException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Integración con Stripe (modo prueba).
///
/// Flujo completo (si hay llave secreta de prueba):
///   1. Se crea un PaymentIntent en la API de Stripe.
///   2. La tarjeta capturada en el formulario NATIVO de Stripe confirma el
///      pago. Los datos de la tarjeta nunca pasan por nuestro código.
///
/// NOTA ACADÉMICA: en producción el paso 1 lo hace un servidor (p. ej. una
/// Cloud Function), porque la llave secreta nunca debe ir en la app. Aquí se
/// usa solo una llave de PRUEBA, que no mueve dinero real.
///
/// Sin llave secreta: Stripe tokeniza y valida la tarjeta (PaymentMethod)
/// y la suscripción se registra como pago simulado.
class PaymentService {
  static bool get isConfigured => _publishableKey.isNotEmpty;
  static bool get canCharge => _secretKey.isNotEmpty;

  static Future<void> init() async {
    if (!isConfigured) {
      debugPrint('[Stripe] Sin STRIPE_PK: los pagos están desactivados.');
      return;
    }
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<PaymentResult> pay({
    required double amountMxn,
    required String description,
    required String name,
    required String email,
  }) async {
    final billing = BillingDetails(name: name, email: email);
    try {
      if (canCharge) {
        final clientSecret = await _createPaymentIntent(
          amountCents: (amountMxn * 100).round(),
          description: description,
          email: email,
        );
        final intent = await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(billingDetails: billing),
          ),
        );
        if (intent.status != PaymentIntentsStatus.Succeeded) {
          throw PaymentException(
              'El pago no se completó (${intent.status.name}).');
        }
        return PaymentResult(id: intent.id, mode: 'payment_intent');
      }

      final method = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(billingDetails: billing),
        ),
      );
      return PaymentResult(
        id: method.id,
        mode: 'payment_method',
        last4: method.card.last4,
        brand: method.card.brand,
      );
    } on StripeException catch (e) {
      throw PaymentException(_spanish(
          e.error.localizedMessage ?? e.error.message ?? 'declined'));
    } on PaymentException {
      rethrow;
    } catch (e) {
      debugPrint('[Stripe] Error: $e');
      throw PaymentException('No se pudo procesar el pago. Revisa tu conexión.');
    }
  }

  /// Mensajes de Stripe más comunes, en español.
  static String _spanish(String message) {
    final m = message.toLowerCase();
    if (m.contains('insufficient')) return 'Fondos insuficientes.';
    if (m.contains('expired')) return 'La tarjeta está vencida.';
    if (m.contains('security code') || m.contains('cvc')) {
      return 'El código de seguridad (CVC) es incorrecto.';
    }
    if (m.contains('declined')) {
      return 'Tu tarjeta fue rechazada. Intenta con otra tarjeta.';
    }
    if (m.contains('canceled') || m.contains('cancelled')) {
      return 'Pago cancelado.';
    }
    return message;
  }

  Future<String> _createPaymentIntent({
    required int amountCents,
    required String description,
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {'Authorization': 'Bearer $_secretKey'},
      body: {
        'amount': '$amountCents',
        'currency': 'mxn',
        'description': description,
        'receipt_email': email,
        // Stripe administra los métodos de pago desde el panel; se
        // desactivan los que redirigen a otra página (solo tarjeta).
        'automatic_payment_methods[enabled]': 'true',
        'automatic_payment_methods[allow_redirects]': 'never',
      },
    ).timeout(const Duration(seconds: 20));

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final error = body['error'] as Map<String, dynamic>?;
      throw PaymentException(
          error?['message']?.toString() ?? 'Stripe rechazó la solicitud.');
    }
    return body['client_secret'] as String;
  }
}
