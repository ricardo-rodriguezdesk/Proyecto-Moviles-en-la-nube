import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    final hasPhoto = url != null && url.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: hasPhoto ? CachedNetworkImageProvider(url) : null,
      // Si falla (sin internet y sin caché), solo se queda el color de fondo.
      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
      child: hasPhoto
          ? null
          : Icon(Icons.person, size: radius, color: scheme.primary),
    );
  }
}
