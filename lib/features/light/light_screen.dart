import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../providers/catalog_provider.dart';
import '../../services/light_sensor_service.dart';
import '../catalog/widgets/plant_visual.dart';
import 'light_meter_controller.dart';
import 'widgets/lux_gauge.dart';

/// Medidor de luz: usa el sensor de luz ambiental del celular para medir
/// los lux de un lugar y recomienda las plantas del catálogo que crecen
/// bien con esa luz.
class LightScreen extends StatelessWidget {
  const LightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LightMeterController(LightSensorService()),
      child: const _LightView(),
    );
  }
}

class _LightView extends StatelessWidget {
  const _LightView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LightMeterController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medidor de luz'),
        actions: [
          IconButton(
            tooltip: '¿Cómo funciona?',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: c.checking
          ? const Center(child: CircularProgressIndicator())
          // Diseño responsivo: en pantallas anchas, medidor y
          // recomendaciones van lado a lado.
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [_MeterPanel()],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [_Recommendations()],
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: const [
                        _MeterPanel(),
                        SizedBox(height: 24),
                        _Recommendations(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Cómo funciona?',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text(
                'Lumen lee el sensor de luz ambiental de tu celular (el que '
                'ajusta el brillo de la pantalla), que mide la luz en lux.\n\n'
                '1. Pon el celular donde quieres la planta, con la pantalla '
                'hacia arriba.\n'
                '2. Espera unos segundos a que la aguja se estabilice.\n'
                '3. Toca "Congelar" y revisa qué plantas te recomendamos.\n\n'
                'Referencia: menos de 1,000 lux es luz baja; de 1,000 a 5,000 '
                'es media; más de 5,000 es alta.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeterPanel extends StatelessWidget {
  const _MeterPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LightMeterController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final level = c.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Origen de la lectura.
        Center(
          child: Chip(
            avatar: Icon(
              c.hasSensor ? Icons.sensors : Icons.touch_app_outlined,
              size: 18,
              color: scheme.primary,
            ),
            label: Text(c.hasSensor
                ? (c.frozen ? 'Lectura congelada' : 'Sensor de luz en vivo')
                : 'Modo manual'),
          ),
        ),
        const SizedBox(height: 8),
        LuxGauge(fraction: c.fraction),
        const SizedBox(height: 8),

        // Valor y nivel.
        Text(
          '${formatLux(c.lux)} lux',
          textAlign: TextAlign.center,
          style: text.displaySmall,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(level.icon, color: scheme.primary),
            const SizedBox(width: 8),
            Text('Luz ${level.label.toLowerCase()}',
                style: text.titleLarge?.copyWith(color: scheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          level.description,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        if (c.hasSensor) ...[
          FilledButton.tonalIcon(
            onPressed: c.toggleFreeze,
            icon: Icon(c.frozen ? Icons.play_arrow : Icons.pause),
            label: Text(c.frozen ? 'Reanudar medición' : 'Congelar lectura'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (c.maxLux > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Máximo medido: ${formatLux(c.maxLux)} lux',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu dispositivo no tiene sensor de luz disponible. '
                    'Elige cuánta luz hay en el lugar:',
                    style: text.bodyMedium,
                  ),
                  Slider(
                    value: c.fraction,
                    onChanged: c.setManualFraction,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Oscuro', style: text.labelSmall),
                      Text('Sol directo', style: text.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LightMeterController>();
    final catalog = context.watch<CatalogProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final plants = catalog.plantsForLux(c.lux);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plants.isEmpty
              ? 'Plantas para este lugar'
              : 'Plantas para este lugar (${plants.length})',
          style: text.titleLarge,
        ),
        const SizedBox(height: 8),
        if (catalog.plants.isEmpty)
          Text('Carga el catálogo desde el inicio para ver recomendaciones.',
              style: text.bodyMedium)
        else if (plants.isEmpty)
          Card(
            child: ListTile(
              leading: Icon(
                c.lux < 100 ? Icons.lightbulb_outline : Icons.wb_sunny,
                color: scheme.primary,
              ),
              title: Text(c.lux < 100
                  ? 'Muy poca luz'
                  : 'Demasiado sol para el catálogo'),
              subtitle: Text(c.lux < 100
                  ? 'Acerca la planta a una ventana o usa una lámpara de cultivo.'
                  : 'Busca un lugar con sombra parcial durante el mediodía.'),
            ),
          )
        else
          for (final p in plants) _PlantTile(plant: p),
      ],
    );
  }
}

class _PlantTile extends StatelessWidget {
  const _PlantTile({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: PlantVisual(plant: plant, emojiSize: 24, borderRadius: 12),
        ),
        title: Text(plant.name),
        subtitle: Text('${plant.luxLabel} · ${plant.wateringLabel}'),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        onTap: () => context.push('/plant/${plant.id}'),
      ),
    );
  }
}
