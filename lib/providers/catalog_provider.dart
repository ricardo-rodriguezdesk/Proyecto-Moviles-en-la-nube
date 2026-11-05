import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/plan.dart';
import '../models/plant.dart';
import '../services/firestore_service.dart';

/// Catálogo de plantas y planes en tiempo real desde Firestore.
/// Solo escucha cuando hay sesión (las reglas exigen usuario autenticado).
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._db);

  final FirestoreService _db;

  StreamSubscription<List<Plant>>? _plantsSub;
  StreamSubscription<List<Plan>>? _plansSub;

  List<Plant> _plants = [];
  List<Plan> _plans = [];
  bool _active = false;
  bool _loading = false;
  bool _seeding = false;
  String? _error;

  List<Plant> get plants => _plants;
  List<Plan> get plans => _plans;
  bool get loading => _loading;
  bool get seeding => _seeding;
  String? get error => _error;
  bool get isEmpty => !_loading && _plants.isEmpty;

  /// Plantas que crecen bien con cierta cantidad de luz (para el sensor).
  List<Plant> plantsForLux(double lux) =>
      _plants.where((p) => p.fitsLux(lux)).toList();

  void setActive(bool active) {
    if (active == _active) return;
    _active = active;
    _plantsSub?.cancel();
    _plansSub?.cancel();
    _plantsSub = null;
    _plansSub = null;

    if (!active) {
      _plants = [];
      _plans = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    _plantsSub = _db.plantsStream().listen(
      (list) {
        _plants = list;
        _loading = false;
        notifyListeners();
      },
      onError: _onError,
    );
    _plansSub = _db.plansStream().listen(
      (list) {
        _plans = list;
        notifyListeners();
      },
      onError: _onError,
    );
  }

  void _onError(Object e) {
    debugPrint('[Catalog] Error de Firestore: $e');
    _error = 'No se pudo cargar el catálogo.';
    _loading = false;
    notifyListeners();
  }

  /// Devuelve null si salió bien, o un mensaje de error.
  Future<String?> seed() async {
    if (_seeding) return null;
    _seeding = true;
    notifyListeners();
    try {
      await _db.seedCatalog();
      return null;
    } catch (e) {
      debugPrint('[Catalog] Error al cargar catálogo: $e');
      return 'No se pudo cargar el catálogo. Revisa las reglas de Firestore.';
    } finally {
      _seeding = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _plantsSub?.cancel();
    _plansSub?.cancel();
    super.dispose();
  }
}
