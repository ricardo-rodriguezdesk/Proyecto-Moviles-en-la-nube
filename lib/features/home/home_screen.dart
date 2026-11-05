import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_inbox.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';

/// Pantalla temporal: comprueba que el login funciona.
/// Más adelante será el dashboard real.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final session = context.watch<SessionProvider>();
    final user = session.user;
    final isDark = themeProvider.isDark(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final name = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? 'Usuario');
    final photo = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumen'),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: Badge(
              isLabelVisible: context.watch<NotificationInbox>().unread > 0,
              label: Text('${context.watch<NotificationInbox>().unread}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              context.read<NotificationInbox>().markAllRead();
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Icon(Icons.person, size: 48, color: scheme.primary)
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Hola, $name',
                  textAlign: TextAlign.center, style: text.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Sesión con: ${user?.providerData.map((p) => p.providerId).join(', ')}',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                session.canEditPhoto
                    ? 'Puedes cambiar tu foto (cuenta de correo)'
                    : 'Tu foto viene de tu proveedor',
                style: text.bodyMedium?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: context.read<OnboardingProvider>().reset,
                child: const Text('Ver onboarding otra vez (prueba)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
