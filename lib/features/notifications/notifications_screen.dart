import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_inbox.dart';
import '../../providers/topics_provider.dart';

/// Ajustes de notificaciones: suscripción a temas + bandeja de recibidas.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificationInbox>();
    final topics = context.watch<TopicsProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Future<void> toggle(String id, bool value) async {
      final messenger = ScaffoldMessenger.of(context);
      final error = await topics.toggle(id, value);
      if (error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (inbox.items.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: inbox.clear,
            ),
        ],
      ),
      body: Center(
        // Diseño responsivo: en pantallas anchas la lista no se estira.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionTitle('Temas que te interesan'),
              for (final t in kTopics)
                SwitchListTile(
                  secondary: Icon(t.icon, color: scheme.primary),
                  title: Text(t.name),
                  subtitle: Text(t.description),
                  value: topics.isSubscribed(t.id),
                  onChanged:
                      topics.isBusy(t.id) ? null : (v) => toggle(t.id, v),
                ),
              const SizedBox(height: 8),
              _SectionTitle('Recibidas'),
              if (inbox.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none,
                          size: 56, color: scheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Aún no recibes notificaciones en esta sesión.',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                for (final n in inbox.items)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(n.origin.icon, color: scheme.primary),
                    ),
                    title: Text(n.title),
                    subtitle: Text(
                      n.body.isEmpty ? n.origin.label : n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(n.time, style: text.labelMedium),
                        const SizedBox(height: 4),
                        Text(n.origin.label,
                            style: text.labelSmall
                                ?.copyWith(color: scheme.primary)),
                      ],
                    ),
                  ),
              const SizedBox(height: 16),
              // Útil para pruebas: enviar un mensaje solo a este dispositivo.
              ExpansionTile(
                leading: const Icon(Icons.key_outlined),
                title: const Text('Token del dispositivo'),
                subtitle: const Text('Para mensajes de prueba'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(
                          inbox.token ?? 'Obteniendo token…',
                          style: text.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: inbox.token == null
                              ? null
                              : () {
                                  Clipboard.setData(
                                      ClipboardData(text: inbox.token!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Token copiado')),
                                  );
                                },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar token'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
