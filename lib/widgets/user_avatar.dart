import 'package:flutter/material.dart';

/// Foto del usuario (de su proveedor o la que subió).
/// Se usa en el inicio y en el perfil, así ambos muestran siempre la misma.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.photoUrl, this.radius = 28});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url == null || url.isEmpty
          ? Icon(Icons.person, size: radius, color: scheme.primary)
          : null,
    );
  }
}
