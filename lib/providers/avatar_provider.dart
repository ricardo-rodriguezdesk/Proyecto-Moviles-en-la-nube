import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart';

/// Foto de perfil guardada en Firestore (respaldo cuando Firebase Storage no
/// está disponible). Se escucha en tiempo real y, gracias a la caché local
/// de Firestore, también se ve sin internet.
class AvatarProvider extends ChangeNotifier {
  AvatarProvider(this._db);

  final FirestoreService _db;
  StreamSubscription<Uint8List?>? _sub;
  String? _uid;
  Uint8List? _bytes;

  Uint8List? get bytes => _bytes;

  void attachUser(String? uid) {
    if (uid == _uid) return;
    _sub?.cancel();
    _uid = uid;
    _bytes = null;
    notifyListeners();
    if (uid == null) return;
    _sub = _db.avatarStream(uid).listen(
      (b) {
        _bytes = b;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('[Avatar] $e'),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
