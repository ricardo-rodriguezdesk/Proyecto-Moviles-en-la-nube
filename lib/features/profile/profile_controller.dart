import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

/// Estado de la pantalla de perfil: subir foto y editar nombre.
/// Los métodos devuelven el mensaje a mostrar (éxito o error),
/// o null si el usuario canceló.
class ProfileController extends ChangeNotifier {
  ProfileController({
    required this.auth,
    required this.storage,
    required this.firestore,
  });

  final AuthService auth;
  final StorageService storage;
  final FirestoreService firestore;

  final _picker = ImagePicker();
  final nameController = TextEditingController();

  bool _uploading = false;
  bool _savingName = false;
  bool _disposed = false;

  bool get uploading => _uploading;
  bool get savingName => _savingName;

  /// Solo se llama si la cuenta es de correo (lo revisa la pantalla).
  Future<String?> changePhoto(ImageSource source) async {
    final user = auth.currentUser;
    if (user == null) return null;

    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
    } catch (e) {
      debugPrint('[Perfil] Error al abrir la cámara/galería: $e');
      return 'No se pudo abrir la ${source == ImageSource.camera ? 'cámara' : 'galería'}.';
    }
    if (picked == null) return null; // canceló

    _uploading = true;
    _notify();
    try {
      final url = await storage.uploadAvatar(user.uid, File(picked.path));
      await auth.updatePhotoUrl(url);
      await firestore.updateProfile(user.uid, photoUrl: url);
      return 'Foto actualizada ✓';
    } on FirebaseException catch (e) {
      debugPrint('[Perfil] Error de Firebase: ${e.code} ${e.message}');
      if (e.code == 'unauthorized') {
        return 'Sin permiso para subir la foto. Revisa las reglas de Storage.';
      }
      return 'No se pudo subir la foto (${e.code}).';
    } catch (e) {
      debugPrint('[Perfil] Error: $e');
      return 'No se pudo subir la foto. Revisa tu conexión.';
    } finally {
      _uploading = false;
      _notify();
    }
  }

  Future<String?> saveName() async {
    final user = auth.currentUser;
    final name = nameController.text.trim();
    if (user == null) return null;
    if (name.length < 2) return 'Escribe un nombre válido.';

    _savingName = true;
    _notify();
    try {
      await auth.updateDisplayName(name);
      await firestore.updateProfile(user.uid, name: name);
      return 'Nombre actualizado ✓';
    } on FirebaseAuthException catch (e) {
      return AuthService.messageFor(e) ?? 'No se pudo guardar el nombre.';
    } catch (e) {
      return 'No se pudo guardar el nombre. Revisa tu conexión.';
    } finally {
      _savingName = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    super.dispose();
  }
}
