import 'package:cloud_firestore/cloud_firestore.dart';

/// Planta del catálogo del vivero (colección `plants` en Firestore).
///
/// `luxMin` / `luxMax` es el rango de luz en el que la planta crece bien.
/// Lo usará el sensor de luz para recomendar plantas según el lugar.
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.light,
    required this.luxMin,
    required this.luxMax,
    required this.wateringDays,
    required this.difficulty,
    required this.petFriendly,
    required this.price,
    required this.emoji,
    this.imageUrl = '',
  });

  factory Plant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Plant(
      id: doc.id,
      name: m['name'] as String? ?? '',
      scientificName: m['scientificName'] as String? ?? '',
      description: m['description'] as String? ?? '',
      light: m['light'] as String? ?? 'Media',
      luxMin: (m['luxMin'] as num?)?.toInt() ?? 0,
      luxMax: (m['luxMax'] as num?)?.toInt() ?? 0,
      wateringDays: (m['wateringDays'] as num?)?.toInt() ?? 7,
      difficulty: m['difficulty'] as String? ?? 'Fácil',
      petFriendly: m['petFriendly'] as bool? ?? false,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      emoji: m['emoji'] as String? ?? '🌿',
      imageUrl: m['imageUrl'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String scientificName;
  final String description;

  /// "Baja", "Media" o "Alta".
  final String light;
  final int luxMin;
  final int luxMax;
  final int wateringDays;

  /// "Fácil", "Media" o "Difícil".
  final String difficulty;
  final bool petFriendly;

  /// Precio en MXN.
  final double price;
  final String emoji;

  /// Se llenará en el paso de Storage.
  final String imageUrl;

  bool fitsLux(double lux) => lux >= luxMin && lux <= luxMax;

  String get wateringLabel => 'Riego cada $wateringDays días';

  String get luxLabel => '$luxMin–$luxMax lux';

  Map<String, dynamic> toMap() => {
        'name': name,
        'scientificName': scientificName,
        'description': description,
        'light': light,
        'luxMin': luxMin,
        'luxMax': luxMax,
        'wateringDays': wateringDays,
        'difficulty': difficulty,
        'petFriendly': petFriendly,
        'price': price,
        'emoji': emoji,
        'imageUrl': imageUrl,
      };
}
