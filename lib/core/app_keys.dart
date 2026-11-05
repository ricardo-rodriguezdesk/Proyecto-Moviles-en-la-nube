import 'package:flutter/material.dart';

/// ScaffoldMessenger de toda la app. Permite mostrar avisos (SnackBars)
/// desde cualquier lugar, aunque no tengamos un BuildContext a la mano.
/// Lo usa el listener global de notificaciones.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();
