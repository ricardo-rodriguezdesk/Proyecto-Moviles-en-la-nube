import 'package:latlong2/latlong.dart';

/// Datos del vivero (establecimiento ficticio para el proyecto).
class StoreInfo {
  StoreInfo._();

  static const name = 'Vivero Lumen';
  static const address = 'Centro, Celaya, Guanajuato';
  static const phone = '461 000 0000';

  /// Ubicación en el mapa (zona centro de Celaya).
  static const location = LatLng(20.5222, -100.8122);

  static const hours = [
    ('Lunes a viernes', '9:00 – 19:00'),
    ('Sábado', '9:00 – 15:00'),
    ('Domingo', 'Cerrado'),
  ];

  /// Abre la ruta en la app de mapas del teléfono.
  static Uri get directionsUri => Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${location.latitude},${location.longitude}',
      );
}
