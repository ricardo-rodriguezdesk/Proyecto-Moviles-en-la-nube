import 'dart:io';

import 'package:flutter/services.dart';

/// Acceso al sensor de luz ambiental nativo (ver MainActivity.kt).
///
/// En iPhone no existe API pública para este sensor: ahí hasSensor()
/// devuelve false y la app usa el modo manual.
class LightSensorService {
  static const _info = MethodChannel('lumen/light_info');
  static const _events = EventChannel('lumen/light');

  Future<bool> hasSensor() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _info.invokeMethod<bool>('hasSensor') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Lecturas en lux (varias por segundo).
  Stream<double> luxStream() => _events
      .receiveBroadcastStream()
      .map((value) => (value as num).toDouble());
}
