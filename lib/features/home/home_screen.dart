import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/plan.dart';
import '../../models/plant.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/notification_inbox.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/user_avatar.dart';
import '../catalog/widgets/plant_visual.dart';

/// Dashboard: saludo, acceso al medidor de luz, plantas sugeridas,
/// planes y avisos recientes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final session = context.watch<SessionProvider>();
    final inbox = context.watch<NotificationInbox>();
    final catalog = context.watch<CatalogProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = themeProvider.isDark(context);

    final user = session.user;
    final email = user?.email ?? '';
    final name = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!.split(' ').first
        : (email.isNotEmpty ? email.split('@').first : 'Usuario');

    final easy =
        catalog.plants.where((p) => p.difficulty == 'Fácil').take(8).toList();
    final petFriendly =
        catalog.plants.where((p) => p.petFriendly).take(8).toList();

    Future<void> seed() async {
      final messenger = ScaffoldMessenger.of(context);
      final error = await catalog.seed();
      messenger.showSnackBar(SnackBar(
        content: Text(error ?? 'Catálogo cargado en Firestore 🌱'),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumen'),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: Badge(
              isLabelVisible: inbox.unread > 0,
              label: Text('${inbox.unread}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              inbox.markAllRead();
              context.push('/notifications');
            },
          ),
          IconButton(
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggle(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // ---------- Saludo ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go('/profile'),
                  child: Row(
                    children: [
                      UserAvatar(photoUrl: user?.photoURL, radius: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hola, $name 🌿', style: text.headlineSmall),
                            Text(
                              '¿Qué vamos a plantar hoy?',
                              style: text.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- Medidor de luz ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LightCard(onTap: () => context.go('/light')),
              ),
              const SizedBox(height: 24),

              if (catalog.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (catalog.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('🌱', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          const Text(
                            'El catálogo está vacío. Carga las plantas y '
                            'planes de ejemplo.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: catalog.seeding ? null : seed,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Cargar catálogo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                _SectionHeader(
                  title: 'Fáciles de cuidar',
                  action: 'Ver todas',
                  onAction: () => context.go('/catalog'),
                ),
                _PlantCarousel(plants: easy),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Seguras para mascotas',
                  action: 'Ver todas',
                  onAction: () => context.go('/catalog'),
                ),
                _PlantCarousel(plants: petFriendly),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Planes mensuales'),
                _PlansRow(plans: catalog.plans),
              ],

              // ---------- Avisos ----------
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Avisos recientes',
                action: inbox.items.isEmpty ? null : 'Ver todos',
                onAction: () => context.push('/notifications'),
              ),
              if (inbox.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Sin avisos por ahora.',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                for (final n in inbox.items.take(2))
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.notifications_outlined,
                          color: scheme.primary),
                    ),
                    title: Text(n.title),
                    subtitle: Text(n.body,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(n.time, style: text.labelSmall),
                    onTap: () => context.push('/notifications'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightCard extends StatelessWidget {
  const _LightCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Cuánta luz hay en tu espacio?',
                          style: text.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        'Mide la luz con tu celular y descubre qué plantas '
                        'crecen ahí.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.tonalIcon(
                        onPressed: onTap,
                        icon: const Icon(Icons.wb_sunny_outlined),
                        label: const Text('Medir luz'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.wb_sunny, size: 72, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _PlantCarousel extends StatelessWidget {
  const _PlantCarousel({required this.plants});

  final List<Plant> plants;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: plants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = plants[i];
          return SizedBox(
            width: 140,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/plant/${p.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 130,
                    width: 140,
                    child: PlantVisual(plant: p, emojiSize: 52),
                  ),
                  const SizedBox(height: 8),
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall),
                  Text(
                    '\$${p.price.toStringAsFixed(0)} · luz ${p.light.toLowerCase()}',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlansRow extends StatelessWidget {
  const _PlansRow({required this.plans});

  final List<Plan> plans;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = plans[i];
          return SizedBox(
            width: 200,
            child: Card(
              color: p.highlight ? scheme.primaryContainer : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Las suscripciones llegan pronto 🌱')),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(p.name, style: text.titleLarge)),
                          if (p.highlight)
                            Icon(Icons.star, color: scheme.primary, size: 20),
                        ],
                      ),
                      const Spacer(),
                      Text('\$${p.price.toStringAsFixed(0)}',
                          style: text.headlineSmall),
                      Text(
                        '${p.plantsPerMonth} '
                        '${p.plantsPerMonth == 1 ? 'planta' : 'plantas'} al mes',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
