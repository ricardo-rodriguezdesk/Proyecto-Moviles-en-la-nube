import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/widgets/auth_widgets.dart' show showMessage;
import 'store_info.dart';
import 'store_map_controller.dart';

/// Ubicación física del vivero en un mapa nativo.
///
/// flutter_map dibuja el mapa con widgets de Flutter (no es un WebView)
/// usando las teselas de OpenStreetMap, que no requieren API key.
class StoreMapScreen extends StatelessWidget {
  const StoreMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoreMapController(),
      child: const _StoreMapView(),
    );
  }
}

class _StoreMapView extends StatelessWidget {
  const _StoreMapView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StoreMapController>();
    final scheme = Theme.of(context).colorScheme;

    Future<void> locate() async {
      final messenger = ScaffoldMessenger.of(context);
      showMessage(messenger, await c.locateUser());
    }

    final map = FlutterMap(
      mapController: c.map,
      options: const MapOptions(
        initialCenter: StoreInfo.location,
        initialZoom: 16,
        minZoom: 4,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ricardoarellano.lumen',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: StoreInfo.location,
              width: 56,
              height: 56,
              alignment: Alignment.topCenter,
              child: _StorePin(color: scheme.primary),
            ),
            if (c.user != null)
              Marker(
                point: c.user!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, color: Colors.black26),
                    ],
                  ),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'Colaboradores de OpenStreetMap',
              onTap: () => launchUrl(
                Uri.parse('https://openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ],
    );

    final fabs = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'fab-store',
          tooltip: 'Centrar en el vivero',
          onPressed: c.centerOnStore,
          child: const Icon(Icons.storefront),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'fab-me',
          tooltip: 'Mi ubicación',
          onPressed: c.locating ? null : locate,
          child: c.locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Visítanos')),
      // Diseño responsivo: en pantallas anchas la información va al lado.
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return Row(
              children: [
                Expanded(
                  child: Stack(children: [
                    map,
                    Positioned(right: 16, top: 16, child: fabs),
                  ]),
                ),
                SizedBox(
                  width: 360,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [_StoreInfoCard()],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(
                child: Stack(children: [
                  map,
                  Positioned(right: 16, top: 16, child: fabs),
                ]),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.45,
                ),
                child: const SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _StoreInfoCard(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StorePin extends StatelessWidget {
  const _StorePin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(Icons.location_on, size: 56, color: color),
        const Positioned(
          top: 9,
          child: Icon(Icons.eco, size: 20, color: Colors.white),
        ),
      ],
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  const _StoreInfoCard();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StoreMapController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final km = c.distanceKm;

    Future<void> directions() async {
      final messenger = ScaffoldMessenger.of(context);
      showMessage(messenger, await c.openDirections());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(StoreInfo.name, style: text.headlineSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(StoreInfo.address, style: text.bodyMedium)),
          ],
        ),
        if (km != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.directions_walk, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                km < 1
                    ? 'A ${(km * 1000).round()} m de ti'
                    : 'A ${km.toStringAsFixed(1)} km de ti',
                style: text.bodyMedium?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final (days, time) in StoreInfo.hours)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(days, style: text.bodyMedium)),
                        Text(time, style: text.bodyMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: directions,
          icon: const Icon(Icons.directions),
          label: const Text('Cómo llegar'),
        ),
      ],
    );
  }
}
