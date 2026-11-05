import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/catalog_provider.dart';
import '../../providers/notification_inbox.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';

/// Pantalla temporal: comprueba sesión + datos de Firestore.
/// En el paso 4 se convierte en el dashboard real.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final session = context.watch<SessionProvider>();
    final inbox = context.watch<NotificationInbox>();
    final catalog = context.watch<CatalogProvider>();
    final user = session.user;
    final isDark = themeProvider.isDark(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final email = user?.email ?? '';
    final name = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (email.isNotEmpty ? email.split('@').first : 'Usuario');
    final photo = user?.photoURL;

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
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: session.signOut,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage:
                        photo != null ? NetworkImage(photo) : null,
                    child: photo == null
                        ? Icon(Icons.person, color: scheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, $name', style: text.headlineSmall),
                        Text(
                          session.canEditPhoto
                              ? 'Cuenta de correo · puedes cambiar tu foto'
                              : 'Foto de tu proveedor',
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------- Planes (Firestore) ----------
              Text('Planes', style: text.titleLarge),
              const SizedBox(height: 8),
              if (catalog.plans.isEmpty)
                Text('Sin planes todavía.',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in catalog.plans)
                      Chip(
                        avatar: p.highlight
                            ? Icon(Icons.star, size: 18, color: scheme.primary)
                            : null,
                        label: Text(
                            '${p.name} · \$${p.price.toStringAsFixed(0)}/mes'),
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // ---------- Plantas (Firestore) ----------
              Row(
                children: [
                  Expanded(
                      child: Text('Catálogo', style: text.titleLarge)),
                  if (catalog.plants.isNotEmpty)
                    Text('${catalog.plants.length} plantas',
                        style: text.labelLarge
                            ?.copyWith(color: scheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              if (catalog.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (catalog.error != null)
                Text(catalog.error!, style: TextStyle(color: scheme.error))
              else if (catalog.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        const Text(
                          'El catálogo está vacío. Carga las plantas y planes '
                          'de ejemplo en Firestore.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: catalog.seeding ? null : seed,
                          icon: catalog.seeding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Cargar catálogo'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final p in catalog.plants)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text(p.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                          'Luz ${p.light.toLowerCase()} · ${p.luxLabel}\n'
                          '${p.wateringLabel} · ${p.difficulty}'),
                      isThreeLine: true,
                      trailing: Text('\$${p.price.toStringAsFixed(0)}',
                          style: text.titleMedium),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
