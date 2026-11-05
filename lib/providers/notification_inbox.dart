import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// En qué estado estaba la app cuando llegó (o se abrió) la notificación.
/// Sirve para demostrar en la evaluación los 3 estados del ciclo de vida.
enum NotificationOrigin {
  foreground('Primer plano', Icons.phone_android),
  background('Segundo plano', Icons.layers_outlined),
  terminated('App cerrada', Icons.power_settings_new);

  const NotificationOrigin(this.label, this.icon);
  final String label;
  final IconData icon;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.origin,
    required this.receivedAt,
    this.data = const {},
  });

  factory AppNotification.fromRemote(
    RemoteMessage m,
    NotificationOrigin origin,
  ) {
    return AppNotification(
      id: m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: m.notification?.title ?? m.data['title']?.toString() ?? 'Lumen',
      body: m.notification?.body ?? m.data['body']?.toString() ?? '',
      origin: origin,
      receivedAt: DateTime.now(),
      data: m.data,
    );
  }

  final String id;
  final String title;
  final String body;
  final NotificationOrigin origin;
  final DateTime receivedAt;
  final Map<String, dynamic> data;

  String get time {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(receivedAt.hour)}:${two(receivedAt.minute)}';
  }
}

/// Bandeja de notificaciones recibidas durante la sesión + token del
/// dispositivo. La UI la escucha con context.watch.
class NotificationInbox extends ChangeNotifier {
  final List<AppNotification> _items = [];
  int _unread = 0;
  String? _token;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unread => _unread;
  String? get token => _token;

  void add(AppNotification n) {
    // Evita duplicados (p. ej. getInitialMessage tras un hot restart).
    if (_items.any((e) => e.id == n.id)) return;
    _items.insert(0, n);
    _unread++;
    notifyListeners();
  }

  void markAllRead() {
    if (_unread == 0) return;
    _unread = 0;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _unread = 0;
    notifyListeners();
  }

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }
}
