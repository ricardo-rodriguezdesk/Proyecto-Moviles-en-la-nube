import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/avatar_provider.dart';

/// Foto del usuario (de su proveedor o la que subió).
/// Se usa en el inicio y en el perfil, así ambos muestran siempre la misma.
///
/// Usa CachedNetworkImageProvider: la foto se descarga una vez y se guarda
/// en el dispositivo, así se sigue viendo aunque no haya internet.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.photoUrl, this.radius = 28});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = photoUrl;
    // Foto subida por el usuario y guardada en Firestore (respaldo de
    // Storage): tiene prioridad sobre la del proveedor.
    final saved = context.watch<AvatarProvider>().bytes;
    final hasPhoto = saved != null || (url != null && url.isNotEmpty);

    final ImageProvider? image = saved != null
        ? MemoryImage(saved)
        : (hasPhoto ? CachedNetworkImageProvider(url!) : null);

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: image,
      // Si falla (sin internet y sin caché), solo se queda el color de fondo.
      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
      child: hasPhoto
          ? null
          : Icon(Icons.person, size: radius, color: scheme.primary),
    );
  }
}
