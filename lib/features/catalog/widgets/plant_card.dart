import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/plant.dart';
import 'plant_visual.dart';

/// Tarjeta de planta para la cuadrícula del catálogo.
/// La imagen usa Hero para animarse hacia la pantalla de detalle.
class PlantCard extends StatelessWidget {
  const PlantCard({super.key, required this.plant, this.useHero = true});

  final Plant plant;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final visual = PlantVisual(plant: plant, borderRadius: 12);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/plant/${plant.id}'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: useHero
                      ? Hero(tag: 'plant-${plant.id}', child: visual)
                      : visual,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(lightIcon(plant.light), size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Luz ${plant.light.toLowerCase()}',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  if (plant.petFriendly)
                    Icon(Icons.pets, size: 14, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '\$${plant.price.toStringAsFixed(0)}',
                style: text.titleSmall?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
