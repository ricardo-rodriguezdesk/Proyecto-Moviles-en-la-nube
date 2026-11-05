import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../providers/catalog_provider.dart';
import 'widgets/plant_card.dart';

/// Filtros del catálogo (búsqueda, luz, mascotas). Sin setState:
/// el estado vive en este ChangeNotifier.
class CatalogFilter extends ChangeNotifier {
  final search = TextEditingController();
  String? _light; // null = todas
  bool _petOnly = false;

  CatalogFilter() {
    search.addListener(notifyListeners);
  }

  String? get light => _light;
  bool get petOnly => _petOnly;
  bool get hasFilters =>
      _light != null || _petOnly || search.text.trim().isNotEmpty;

  void setLight(String? value) {
    _light = value;
    notifyListeners();
  }

  void togglePet() {
    _petOnly = !_petOnly;
    notifyListeners();
  }

  void clear() {
    _light = null;
    _petOnly = false;
    search.clear();
  }

  List<Plant> apply(List<Plant> plants) {
    final q = search.text.trim().toLowerCase();
    return plants.where((p) {
      if (_light != null && p.light != _light) return false;
      if (_petOnly && !p.petFriendly) return false;
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.scientificName.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CatalogFilter(),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final filter = context.watch<CatalogFilter>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final plants = filter.apply(catalog.plants);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: filter.search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar plantas',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: filter.search.clear,
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final option in const [null, 'Baja', 'Media', 'Alta'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option == null ? 'Todas' : 'Luz $option'),
                      selected: filter.light == option,
                      onSelected: (_) => filter.setLight(option),
                    ),
                  ),
                FilterChip(
                  avatar: const Icon(Icons.pets, size: 16),
                  label: const Text('Seguras para mascotas'),
                  selected: filter.petOnly,
                  onSelected: (_) => filter.togglePet(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: catalog.loading
                ? const Center(child: CircularProgressIndicator())
                : plants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 56, color: scheme.outline),
                            const SizedBox(height: 12),
                            Text('No hay plantas con esos filtros',
                                style: text.bodyLarge),
                            if (filter.hasFilters)
                              TextButton(
                                onPressed: filter.clear,
                                child: const Text('Quitar filtros'),
                              ),
                          ],
                        ),
                      )
                    // Diseño responsivo: más columnas en pantallas anchas.
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final columns =
                              (constraints.maxWidth / 200).floor().clamp(2, 6);
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: plants.length,
                            itemBuilder: (_, i) => PlantCard(plant: plants[i]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
