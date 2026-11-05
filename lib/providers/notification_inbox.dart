import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

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
    this.read = false,
    this.data = const {},
  });

  factory AppNotification.fromRemote(
    RemoteMessage m,
    NotificationOrigin origin,
  ) {
    final rawId =
        m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString();
    return AppNotification(
      // Firestore no acepta "/" en los IDs de documento.
      id: rawId.replaceAll('/', '_'),
      title: m.notification?.title ?? m.data['title']?.toString() ?? 'Lumen',
      body: m.notification?.body ?? m.data['body']?.toString() ?? '',
      origin: origin,
      receivedAt: DateTime.now(),
      data: Map<String, dynamic>.from(m.data),
    );
  }

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppNotification(
      id: d.id,
      title: m['title'] as String? ?? 'Lumen',
      body: m['body'] as String? ?? '',
      origin: NotificationOrigin.values.firstWhere(
        (o) => o.name == m['origin'],
        orElse: () => NotificationOrigin.foreground,
      ),
      receivedAt: (m['receivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: m['read'] as bool? ?? false,
      data: Map<String, dynamic>.from(m['data'] as Map? ?? {}),
    );
  }

  final String id;
  final String title;
  final String body;
  final NotificationOrigin origin;
  final DateTime receivedAt;
  final bool read;
  final Map<String, dynamic> data;

  String get time {
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay = now.year == receivedAt.year &&
        now.month == receivedAt.month &&
        now.day == receivedAt.day;
    final hour = '${two(receivedAt.hour)}:${two(receivedAt.minute)}';
    return sameDay ? hour : '${two(receivedAt.day)}/${two(receivedAt.month)} $hour';
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'origin': origin.name,
        'receivedAt': Timestamp.fromDate(receivedAt),
        'read': read,
        'data': data,
      };
}

/// Bandeja de notificaciones guardada en Firestore
/// (users/{uid}/notifications), así el historial sobrevive aunque se
/// cierre la app. Si llega algo antes de iniciar sesión, se guarda en
/// memoria y se sube en cuanto hay usuario.
class NotificationInbox extends ChangeNotifier {
  NotificationInbox(this._db);

  final FirestoreService _db;

  String? _uid;
  String? _token;
  StreamSubscription<List<AppNotification>>? _sub;
  List<AppNotification> _items = [];
  final List<AppNotification> _pending = [];

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unread => _items.where((n) => !n.read).length;
  String? get token => _token;

  /// Se llama cada vez que cambia la sesión (login / logout).
  void attachUser(String? uid) {
    if (uid == _uid) return;
    _sub?.cancel();
    _sub = null;
    _uid = uid;
    _items = [];

    if (uid == null) {
      notifyListeners();
      return;
    }

    for (final n in _pending) {
      _db.saveNotification(uid, n);
    }
    _pending.clear();

    if (_token != null) _db.saveFcmToken(uid, _token!);

    _sub = _db.notificationsStream(uid).listen(
      (list) {
        _items = list;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('[Inbox] Error de Firestore: $e'),
    );
    notifyListeners();
  }

  void add(AppNotification n) {
    final uid = _uid;
    if (uid == null) {
      if (_pending.any((e) => e.id == n.id)) return;
      _pending.add(n);
      _items = [n, ..._items];
      notifyListeners();
      return;
    }
    // Firestore actualiza el stream al instante (aun sin internet).
    _db.saveNotification(uid, n);
  }

  void markAllRead() {
    final uid = _uid;
    final ids = _items.where((n) => !n.read).map((n) => n.id).toList();
    if (uid == null || ids.isEmpty) return;
    _db.markAllRead(uid, ids);
  }

  void clear() {
    final uid = _uid;
    if (uid == null) {
      _items = [];
      _pending.clear();
      notifyListeners();
      return;
    }
    _db.deleteNotifications(uid, _items.map((n) => n.id).toList());
  }

  void setToken(String? token) {
    _token = token;
    if (_uid != null && token != null) _db.saveFcmToken(_uid!, token);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
