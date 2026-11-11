import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/light_sensor_service.dart';

/// Nivel de luz según los lux medidos.
enum LightLevel {
  veryLow('Muy baja', 'Demasiado oscuro para casi cualquier planta.',
      Icons.nightlight_outlined),
  low('Baja', 'Lejos de ventanas o en pasillos. Ideal para plantas resistentes.',
      Icons.wb_cloudy_outlined),
  medium('Media', 'Cerca de una ventana con luz indirecta. La mayoría crece bien.',
      Icons.wb_twilight),
  high('Alta', 'Junto a la ventana o con sol directo. Perfecto para suculentas.',
      Icons.wb_sunny);

  const LightLevel(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;

  static LightLevel fromLux(double lux) {
    if (lux < 100) return LightLevel.veryLow;
    if (lux < 1000) return LightLevel.low;
    if (lux < 5000) return LightLevel.medium;
    return LightLevel.high;
  }
}

/// Escala logarítmica del medidor: 1 lux → 0.0, 100,000 lux → 1.0.
/// (La luz va de 1 a 100,000 lux; en escala lineal casi todo quedaría
/// pegado al inicio del medidor.)
const double kMaxLuxExponent = 5;

double luxToFraction(double lux) =>
    (math.log(lux.clamp(1, 100000)) / math.ln10) / kMaxLuxExponent;

double fractionToLux(double fraction) =>
    math.pow(10, fraction.clamp(0, 1) * kMaxLuxExponent).toDouble();

String formatLux(double lux) {
  if (lux < 10) return lux.toStringAsFixed(1);
  return lux.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}

/// Estado del medidor de luz (sin setState).
///  - Con sensor: escucha las lecturas, las suaviza y permite congelarlas.
///  - Sin sensor (iPhone o dispositivos sin él): modo manual con slider.
class LightMeterController extends ChangeNotifier {
  LightMeterController(this._service) {
    _start();
  }

  final LightSensorService _service;
  StreamSubscription<double>? _sub;

  bool _checking = true;
  bool _hasSensor = false;
  bool _frozen = false;
  bool _disposed = false;
  double _lux = 1500; // valor inicial del modo manual
  double _maxLux = 0;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  bool get checking => _checking;
  bool get hasSensor => _hasSensor;
  bool get manual => !_hasSensor;
  bool get frozen => _frozen;
  double get lux => _lux;
  double get maxLux => _maxLux;
  double get fraction => luxToFraction(_lux);
  LightLevel get level => LightLevel.fromLux(_lux);

  Future<void> _start() async {
    _hasSensor = await _service.hasSensor();
    _checking = false;
    _notify(force: true);
    if (!_hasSensor) return;

    _sub = _service.luxStream().listen(
      (value) {
        if (_frozen) return;
        // Se usa el valor tal cual: el sensor de luz de Android solo envía
        // lecturas cuando el valor cambia, así que suavizar aquí dejaría la
        // aguja a medio camino. La animación del medidor ya la mueve suave.
        _lux = value;
        _maxLux = math.max(_maxLux, _lux);
        // Siempre notificar la lectura más reciente (aunque llegue rápido).
        _notify(force: true);
      },
      onError: (Object e) {
        debugPrint('[Luz] Error del sensor: $e');
        _hasSensor = false;
        _notify(force: true);
      },
    );
  }

  /// Modo manual: el slider se mueve en escala logarítmica.
  void setManualFraction(double fraction) {
    _lux = fractionToLux(fraction);
    _notify(force: true);
  }

  void toggleFreeze() {
    _frozen = !_frozen;
    _notify(force: true);
  }

  // Máximo ~7 redibujados por segundo: suficiente y ahorra batería.
  void _notify({bool force = false}) {
    if (_disposed) return;
    final now = DateTime.now();
    if (!force &&
        now.difference(_lastNotify) < const Duration(milliseconds: 150)) {
      return;
    }
    _lastNotify = now;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel(); // libera el sensor (onCancel en Kotlin)
    super.dispose();
  }
}
