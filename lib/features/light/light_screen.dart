import 'package:flutter/material.dart';

/// Pantalla del medidor de luz. El sensor se conecta en un paso posterior.
class LightScreen extends StatelessWidget {
  const LightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Medidor de luz')),
      body: Center(
        // Con scroll para que no se desborde en horizontal (pantalla baja).
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.tertiaryContainer, scheme.primaryContainer],
                  ),
                ),
                child: Icon(Icons.wb_sunny, size: 72, color: scheme.primary),
              ),
              const SizedBox(height: 24),
              Text('Muy pronto', style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Usarás el sensor de luz de tu celular para saber qué plantas '
                'crecen bien en cada rincón de tu casa.',
                textAlign: TextAlign.center,
                style:
                    text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
