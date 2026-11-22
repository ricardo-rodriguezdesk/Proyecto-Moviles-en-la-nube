import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/plan.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';

/// Suscripción activa del usuario (campo `subscription` en users/{uid}).
class ActiveSubscription {
  const ActiveSubscription({
    required this.planId,
    required this.planName,
    required this.price,
    required this.since,
  });

  factory ActiveSubscription.fromMap(Map<String, dynamic> m) =>
      ActiveSubscription(
        planId: m['planId'] as String? ?? '',
        planName: m['planName'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        since: (m['since'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  final String planId;
  final String planName;
  final double price;
  final DateTime since;

  DateTime get nextCharge =>
      DateTime(since.year, since.month + 1, since.day);
}

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._db);

  final FirestoreService _db;
  StreamSubscription<ActiveSubscription?>? _sub;
  String? _uid;
  ActiveSubscription? _active;

  ActiveSubscription? get active => _active;

  void attachUser(String? uid) {
    if (uid == _uid) return;
    _sub?.cancel();
    _uid = uid;
    _active = null;
    notifyListeners();
    if (uid == null) return;
    _sub = _db.subscriptionStream(uid).listen(
      (s) {
        _active = s;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('[Suscripción] $e'),
    );
  }

  Future<void> activate(Plan plan, PaymentResult payment) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.saveSubscription(uid, plan, payment);
  }

  Future<void> cancel() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.cancelSubscription(uid);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
