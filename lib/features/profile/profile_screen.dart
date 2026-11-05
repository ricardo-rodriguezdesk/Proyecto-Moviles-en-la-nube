import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/onboarding_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/user_avatar.dart';
import '../auth/widgets/auth_widgets.dart' show showMessage;
import 'profile_controller.dart';

const _providerNames = {
  'password': 'Correo',
  'google.com': 'Google',
  'github.com': 'GitHub',
};

const _providerIcons = {
  'password': Icons.mail_outline,
  'google.com': Icons.g_mobiledata,
  'github.com': Icons.code,
};

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ProfileController(
        auth: ctx.read<AuthService>(),
        storage: ctx.read<StorageService>(),
        firestore: ctx.read<FirestoreService>(),
      ),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileController>();
    final session = context.watch<SessionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = session.user;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final email = user?.email ?? '';
    final name = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (email.isNotEmpty ? email.split('@').first : 'Usuario');
    final photo = user?.photoURL;
    final providers =
        user?.providerData.map((p) => p.providerId).toSet().toList() ?? [];
    final externalProvider = providers
        .where((p) => p != 'password')
        .map((p) => _providerNames[p] ?? p)
        .join(' / ');

    Future<void> pickPhoto() async {
      final messenger = ScaffoldMessenger.of(context);
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (source == null) return;
      showMessage(messenger, await c.changePhoto(source));
    }

    Future<void> editName() async {
      final messenger = ScaffoldMessenger.of(context);
      c.nameController.text = name;
      final save = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tu nombre'),
          content: TextField(
            controller: c.nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre'),
            onSubmitted: (_) => Navigator.pop(ctx, true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (save == true) showMessage(messenger, await c.saveName());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Center(
        // Diseño responsivo: en tablet/escritorio no se estira.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ---------- Foto ----------
              Center(
                child: Stack(
                  children: [
                    UserAvatar(photoUrl: photo, radius: 64),
                    if (c.uploading)
                      Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: const CircularProgressIndicator(
                              color: Colors.white),
                        ),
                      ),
                    if (session.canEditPhoto)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          tooltip: 'Cambiar foto',
                          onPressed: c.uploading ? null : pickPhoto,
                          icon: const Icon(Icons.photo_camera),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!session.canEditPhoto)
                Text(
                  'Tu foto viene de $externalProvider. Solo las cuentas '
                  'de correo pueden cambiarla.',
                  textAlign: TextAlign.center,
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              const SizedBox(height: 16),

              // ---------- Nombre y correo ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(name,
                        textAlign: TextAlign.center,
                        style: text.headlineSmall),
                  ),
                  IconButton(
                    tooltip: 'Editar nombre',
                    onPressed: c.savingName ? null : editName,
                    icon: c.savingName
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined, size: 20),
                  ),
                ],
              ),
              Text(email,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final p in providers)
                    Chip(
                      avatar: Icon(_providerIcons[p] ?? Icons.person, size: 18),
                      label: Text(_providerNames[p] ?? p),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------- Cuenta ----------
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        (user?.emailVerified ?? false) || !session.usesPassword
                            ? Icons.verified_outlined
                            : Icons.error_outline,
                        color: scheme.primary,
                      ),
                      title: const Text('Correo verificado'),
                      subtitle: Text(session.usesPassword
                          ? ((user?.emailVerified ?? false) ? 'Sí' : 'No')
                          : 'Verificado por $externalProvider'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.workspace_premium_outlined,
                          color: scheme.primary),
                      title: const Text('Mi plan'),
                      subtitle: const Text('Sin plan activo'),
                      trailing: const Icon(Icons.chevron_right),
                      // Se conecta en el paso de pagos.
                      onTap: () => showMessage(
                        ScaffoldMessenger.of(context),
                        'Los planes llegan pronto 🌱',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ---------- Preferencias ----------
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary:
                          Icon(Icons.dark_mode_outlined, color: scheme.primary),
                      title: const Text('Modo oscuro'),
                      value: themeProvider.isDark(context),
                      onChanged: (v) => themeProvider
                          .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.notifications_outlined,
                          color: scheme.primary),
                      title: const Text('Notificaciones'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/notifications'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.replay_outlined,
                          color: scheme.primary),
                      title: const Text('Ver bienvenida otra vez'),
                      onTap: context.read<OnboardingProvider>().reset,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: session.signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: scheme.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
