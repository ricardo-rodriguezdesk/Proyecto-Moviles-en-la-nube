import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Indica si el dispositivo tiene conexión. La app muestra un aviso
/// "Sin conexión" y sigue funcionando con los datos guardados
/// (caché de imágenes + caché local de Firestore).
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _init();
  }

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  bool get online => _online;

  Future<void> _init() async {
    try {
      _update(await _connectivity.checkConnectivity());
    } catch (e) {
      debugPrint('[Conexión] No se pudo revisar: $e');
    }
    _sub = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _online) return;
    _online = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
