import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/seed_data.dart';
import '../models/plan.dart';
import '../models/plant.dart';
import '../providers/notification_inbox.dart';

/// Todo el acceso a Cloud Firestore pasa por aquí.
///
/// Estructura de la base de datos:
///   plants/{plantId}                          → catálogo del vivero
///   plans/{planId}                            → planes de suscripción
///   users/{uid}                               → perfil del usuario
///   users/{uid}/notifications/{messageId}     → historial de notificaciones
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plants =>
      _db.collection('plants');
  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection('plans');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _users.doc(uid).collection('notifications');

  // ---------------- Catálogo ----------------

  Stream<List<Plant>> plantsStream() => _plants
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Plant.fromDoc).toList());

  Stream<List<Plan>> plansStream() => _plans
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(Plan.fromDoc).toList());

  /// Sube las plantas y planes de ejemplo (no duplica: usa IDs fijos).
  Future<void> seedCatalog() async {
    final batch = _db.batch();
    for (final p in seedPlants) {
      batch.set(_plants.doc(p.id), p.toMap());
    }
    for (final p in seedPlans) {
      batch.set(_plans.doc(p.id), p.toMap());
    }
    await batch.commit();
  }

  // ---------------- Usuarios ----------------

  /// Crea el documento del usuario la primera vez que inicia sesión y
  /// actualiza la fecha de último acceso en los siguientes.
  Future<void> ensureUserDoc(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'providers': user.providerData.map((p) => p.providerId).toList(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      final email = user.email ?? '';
      data['name'] = (user.displayName?.isNotEmpty ?? false)
          ? user.displayName
          : email.split('@').first;
      data['photoUrl'] = user.photoURL;
      data['plan'] = null;
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> saveFcmToken(String uid, String token) =>
      _users.doc(uid).set({'fcmToken': token}, SetOptions(merge: true));

  // ---------------- Notificaciones ----------------

  Stream<List<AppNotification>> notificationsStream(String uid) =>
      _notifications(uid)
          .orderBy('receivedAt', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Future<void> saveNotification(String uid, AppNotification n) =>
      _notifications(uid).doc(n.id).set(n.toMap());

  Future<void> markAllRead(String uid, Iterable<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_notifications(uid).doc(id), {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotifications(String uid, Iterable<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.delete(_notifications(uid).doc(id));
    }
    await batch.commit();
  }
}
