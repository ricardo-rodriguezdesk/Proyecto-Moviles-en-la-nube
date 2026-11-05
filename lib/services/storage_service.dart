import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Subida de archivos a Firebase Storage.
///
/// Estructura del bucket:
///   users/{uid}/avatar_{timestamp}.jpg   → foto de perfil
///   plants/{plantId}.jpg                 → fotos del catálogo
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube la foto de perfil y devuelve su URL pública de descarga.
  /// El nombre lleva la hora para que la app no muestre una versión vieja.
  Future<String> uploadAvatar(String uid, File file) async {
    final name = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('users/$uid/$name');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
