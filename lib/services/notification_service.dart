import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../firebase_options.dart';
import '../providers/notification_inbox.dart';
import '../providers/topics_provider.dart';

/// Handler para mensajes que llegan con la app en SEGUNDO PLANO o CERRADA.
///
/// Debe ser una función top-level (fuera de cualquier clase) y llevar
/// @pragma('vm:entry-point') para que Android la pueda ejecutar aunque
/// la app no esté abierta. Las notificaciones enviadas desde la consola
/// las muestra Android solo en la bandeja; aquí solo las registramos.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Mensaje en segundo plano: '
      '${message.messageId} · ${message.notification?.title}');
}

/// Listener GLOBAL de notificaciones. Se inicia una sola vez en main()
/// y funciona en todas las pantallas:
///  - Primer plano  → onMessage        → aviso dentro de la app.
///  - Segundo plano → onMessageOpenedApp (al tocar la notificación).
///  - App cerrada   → getInitialMessage  (al tocar la notificación).
class NotificationService {
  NotificationService({
    required this.router,
    required this.inbox,
    required this.topics,
    required this.messengerKey,
  });

  final GoRouter router;
  final NotificationInbox inbox;
  final TopicsProvider topics;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  final _messaging = FirebaseMessaging.instance;
  final List<StreamSubscription> _subs = [];
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    // Android 13+ muestra el diálogo "¿Permitir notificaciones?".
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');

    // Token del dispositivo (sirve para enviar un mensaje de prueba
    // solo a este celular desde la consola).
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Token: $token');
      inbox.setToken(token);
    } catch (e) {
      debugPrint('[FCM] No se pudo obtener el token: $e');
    }
    _subs.add(_messaging.onTokenRefresh.listen(inbox.setToken));

    // 1) Primer plano.
    _subs.add(FirebaseMessaging.onMessage.listen(_onForeground));

    // 2) Segundo plano: el usuario tocó la notificación.
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _onOpened(m, NotificationOrigin.background),
    ));

    // 3) App cerrada: la app se abrió desde una notificación.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onOpened(initial, NotificationOrigin.terminated);

    // Suscripción por defecto al tema "avisos".
    await topics.ensureDefaults();
  }

  void _onForeground(RemoteMessage message) {
    debugPrint('[FCM] Primer plano: ${message.notification?.title}');
    final n = AppNotification.fromRemote(message, NotificationOrigin.foreground);
    inbox.add(n);

    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (n.body.isNotEmpty) Text(n.body),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => _openRoute(message),
          ),
        ),
      );
  }

  void _onOpened(RemoteMessage message, NotificationOrigin origin) {
    debugPrint('[FCM] Abierta desde ${origin.label}: '
        '${message.notification?.title}');
    inbox.add(AppNotification.fromRemote(message, origin));
    _openRoute(message);
  }

  /// Si la notificación trae el dato `route` (p. ej. /notifications),
  /// navegamos ahí. Si no, abrimos la bandeja de notificaciones.
  void _openRoute(RemoteMessage message) {
    final route = message.data['route']?.toString();
    router.go(
        (route != null && route.startsWith('/')) ? route : '/notifications');
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
  }
}
