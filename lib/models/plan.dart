import 'package:cloud_firestore/cloud_firestore.dart';

/// Plan de suscripción mensual (colección `plans` en Firestore).
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.plantsPerMonth,
    required this.features,
    required this.order,
    this.highlight = false,
  });

  factory Plan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Plan(
      id: doc.id,
      name: m['name'] as String? ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0,
      plantsPerMonth: (m['plantsPerMonth'] as num?)?.toInt() ?? 1,
      features: (m['features'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      order: (m['order'] as num?)?.toInt() ?? 0,
      highlight: m['highlight'] as bool? ?? false,
    );
  }

  final String id;
  final String name;

  /// Precio mensual en MXN.
  final double price;
  final int plantsPerMonth;
  final List<String> features;
  final int order;

  /// El plan recomendado (se muestra destacado).
  final bool highlight;

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'plantsPerMonth': plantsPerMonth,
        'features': features,
        'order': order,
        'highlight': highlight,
      };
}
