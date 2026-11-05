import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../providers/catalog_provider.dart';
import 'widgets/plant_visual.dart';

class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final matches = catalog.plants.where((p) => p.id == plantId);

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: catalog.loading
              ? const CircularProgressIndicator()
              : const Text('No encontramos esta planta.'),
        ),
      );
    }

    return _PlantDetailView(plant: matches.first);
  }
}

class _PlantDetailView extends StatelessWidget {
  const _PlantDetailView({required this.plant});

  final Plant plant;

  String get _placement => switch (plant.light) {
        'Baja' => 'Lejos de ventanas, pasillos o rincones con luz suave '
            '(aprox. 100–1,000 lux).',
        'Alta' => 'Junto a una ventana con sol directo varias horas al día '
            '(5,000 lux o más).',
        _ => 'Cerca de una ventana, con luz brillante pero indirecta '
            '(aprox. 1,000–5,000 lux).',
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'plant-${plant.id}',
                child: PlantVisual(
                  plant: plant,
                  emojiSize: 120,
                  borderRadius: 0,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plant.name, style: text.headlineMedium),
                                Text(
                                  plant.scientificName,
                                  style: text.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${plant.price.toStringAsFixed(0)}',
                            style: text.headlineSmall
                                ?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoChip(
                            icon: lightIcon(plant.light),
                            label: 'Luz ${plant.light.toLowerCase()}',
                          ),
                          InfoChip(icon: Icons.light_mode, label: plant.luxLabel),
                          InfoChip(
                            icon: Icons.water_drop_outlined,
                            label: plant.wateringLabel,
                          ),
                          InfoChip(
                            icon: Icons.spa_outlined,
                            label: plant.difficulty,
                          ),
                          InfoChip(
                            icon: plant.petFriendly
                                ? Icons.pets
                                : Icons.warning_amber_outlined,
                            label: plant.petFriendly
                                ? 'Segura para mascotas'
                                : 'Tóxica para mascotas',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(plant.description, style: text.bodyLarge),
                      const SizedBox(height: 20),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.place_outlined,
                              color: scheme.primary),
                          title: const Text('¿Dónde ponerla?'),
                          subtitle: Text(_placement),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.go('/light'),
                        icon: const Icon(Icons.wb_sunny_outlined),
                        label: const Text('Medir la luz de mi espacio'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Las suscripciones llegan pronto 🌱'),
                        )),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Incluir en mi suscripción'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
