import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { authenticated, failed, unavailable }

/// Lector biométrico (huella / rostro, o PIN del dispositivo como respaldo).
/// Se usa para confirmar los pagos.
class BiometricService {
  final _auth = LocalAuthentication();

  Future<BiometricResult> confirm(String reason) async {
    // 1. ¿El dispositivo tiene huella o PIN configurado?
    try {
      final supported = await _auth.isDeviceSupported();
      final enrolled = await _auth.getAvailableBiometrics();
      if (!supported && enrolled.isEmpty) return BiometricResult.unavailable;
    } catch (e) {
      debugPrint('[Biometría] No se pudo revisar el dispositivo: $e');
      return BiometricResult.unavailable;
    }

    // 2. Pedir la huella. Cualquier error aquí BLOQUEA el pago
    //    (no se permite pagar si la verificación falla).
    try {
      final ok = await _auth.authenticate(localizedReason: reason);
      return ok ? BiometricResult.authenticated : BiometricResult.failed;
    } catch (e) {
      debugPrint('[Biometría] Error al autenticar: $e');
      return BiometricResult.failed;
    }
  }
}
