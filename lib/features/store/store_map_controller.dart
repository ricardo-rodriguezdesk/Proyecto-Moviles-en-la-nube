import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'store_info.dart';

/// Estado de la pantalla del mapa (sin setState): ubicación del usuario,
/// distancia al vivero y acciones del mapa.
class StoreMapController extends ChangeNotifier {
  final map = MapController();

  LatLng? _user;
  bool _locating = false;
  bool _disposed = false;

  LatLng? get user => _user;
  bool get locating => _locating;

  /// Distancia en km del usuario al vivero (si se conoce su ubicación).
  double? get distanceKm => _user == null
      ? null
      : Geolocator.distanceBetween(
            _user!.latitude,
            _user!.longitude,
            StoreInfo.location.latitude,
            StoreInfo.location.longitude,
          ) /
          1000;

  void centerOnStore() => map.move(StoreInfo.location, 16);

  /// Pide permiso y obtiene la ubicación. Devuelve un mensaje de error
  /// o null si salió bien. Nunca lanza excepciones (evita crashes).
  Future<String?> locateUser() async {
    if (_locating) return null;
    _locating = true;
    _notify();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Activa la ubicación del dispositivo.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return 'Necesitamos permiso de ubicación para calcular la distancia.';
      }
      if (permission == LocationPermission.deniedForever) {
        return 'El permiso de ubicación está bloqueado. Actívalo en Ajustes.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _user = LatLng(pos.latitude, pos.longitude);

      // Encuadra al usuario y al vivero en la misma vista.
      map.fitCamera(CameraFit.coordinates(
        coordinates: [_user!, StoreInfo.location],
        padding: const EdgeInsets.all(72),
        maxZoom: 16,
      ));
      return null;
    } catch (e) {
      debugPrint('[Mapa] Error de ubicación: $e');
      return 'No se pudo obtener tu ubicación.';
    } finally {
      _locating = false;
      _notify();
    }
  }

  Future<String?> openDirections() async {
    try {
      final ok = await launchUrl(
        StoreInfo.directionsUri,
        mode: LaunchMode.externalApplication,
      );
      return ok ? null : 'No se pudo abrir la app de mapas.';
    } catch (_) {
      return 'No se pudo abrir la app de mapas.';
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    map.dispose();
    super.dispose();
  }
}
