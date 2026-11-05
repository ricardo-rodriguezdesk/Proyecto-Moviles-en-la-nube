import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/plant.dart';

/// Imagen de la planta. Si aún no tiene foto (Storage), muestra su emoji
/// sobre un degradado con un color según la luz que necesita.
class PlantVisual extends StatelessWidget {
  const PlantVisual({
    super.key,
    required this.plant,
    this.emojiSize = 48,
    this.borderRadius = 16,
  });

  final Plant plant;
  final double emojiSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = switch (plant.light) {
      'Baja' => [scheme.secondaryContainer, scheme.surfaceContainerHighest],
      'Alta' => [scheme.tertiaryContainer, scheme.primaryContainer],
      _ => [scheme.primaryContainer, scheme.tertiaryContainer],
    };

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(plant.emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: plant.imageUrl.isEmpty
          ? fallback
          // Se guarda en el dispositivo: la segunda vez carga sin internet.
          : CachedNetworkImage(
              imageUrl: plant.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}

/// Etiqueta pequeña con ícono (luz, riego, etc.).
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

IconData lightIcon(String light) => switch (light) {
      'Baja' => Icons.wb_cloudy_outlined,
      'Alta' => Icons.wb_sunny,
      _ => Icons.wb_twilight,
    };
