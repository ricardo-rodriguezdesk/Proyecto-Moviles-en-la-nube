import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/plan.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/subscription_provider.dart';

/// Modelo de prestación de servicios: 3 planes de suscripción mensual.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<CatalogProvider>().plans;
    final active = context.watch<SubscriptionProvider>().active;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Diseño responsivo: 1 columna en celular, 3 en pantallas anchas.
                final wide = constraints.maxWidth >= 900;
                final cards = [
                  for (final p in plans)
                    _PlanCard(plan: p, isActive: active?.planId == p.id),
                ];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Plantas elegidas para la luz de tu casa, cada mes.',
                        style: text.titleMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    if (wide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final c in cards)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: c,
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      for (final c in cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: c,
                        ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('Pagos seguros procesados por Stripe',
                            style: text.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.isActive});

  final Plan plan;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final highlight = plan.highlight;

    return Card(
      margin: EdgeInsets.zero,
      color: highlight ? scheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isActive
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(plan.name, style: text.headlineSmall)),
                if (highlight && !isActive)
                  Chip(
                    label: const Text('Recomendado'),
                    avatar: Icon(Icons.star, size: 16, color: scheme.primary),
                    visualDensity: VisualDensity.compact,
                  ),
                if (isActive)
                  Chip(
                    label: const Text('Tu plan'),
                    avatar: Icon(Icons.check_circle,
                        size: 16, color: scheme.primary),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: '\$${plan.price.toStringAsFixed(0)}',
                  style: text.displaySmall),
              TextSpan(text: ' MXN / mes', style: text.bodyMedium),
            ])),
            const SizedBox(height: 12),
            for (final f in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isActive
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Plan actual'),
                    )
                  : FilledButton(
                      onPressed: () => context.push('/checkout/${plan.id}'),
                      child: Text('Elegir ${plan.name}'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
