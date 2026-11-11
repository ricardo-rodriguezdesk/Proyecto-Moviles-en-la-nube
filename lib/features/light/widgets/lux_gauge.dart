import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Medidor de luz semicircular dibujado a mano con CustomPainter
/// (widget avanzado). La aguja se anima con TweenAnimationBuilder,
/// sin setState.
class LuxGauge extends StatelessWidget {
  const LuxGauge({super.key, required this.fraction});

  /// Posición de la aguja: 0.0 (1 lux) a 1.0 (100,000 lux), escala log.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    return AspectRatio(
      aspectRatio: 1.7,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fraction.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _LuxGaugePainter(
            fraction: value,
            zoneColors: [
              scheme.outlineVariant, // muy baja
              scheme.secondary, // baja
              scheme.primary, // media
              Colors.amber.shade600, // alta
            ],
            trackColor: scheme.surfaceContainerHighest,
            needleColor: scheme.onSurface,
            labelStyle: labelStyle ?? const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _LuxGaugePainter extends CustomPainter {
  _LuxGaugePainter({
    required this.fraction,
    required this.zoneColors,
    required this.trackColor,
    required this.needleColor,
    required this.labelStyle,
  });

  final double fraction;
  final List<Color> zoneColors;
  final Color trackColor;
  final Color needleColor;
  final TextStyle labelStyle;

  // Límites de cada zona en la escala 0..1 (log10(lux) / 5):
  // 100 lux = 0.4, 1,000 lux = 0.6, 5,000 lux ≈ 0.74, 100,000 lux = 1.0
  static const _zoneStops = [0.0, 0.4, 0.6, 0.7398, 1.0];
  static const _tickLabels = ['1', '10', '100', '1k', '10k', '100k'];

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final center = Offset(size.width / 2, size.height - 12);
    final radius = math.min(size.width / 2, size.height) - 34;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Fondo del arco.
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round,
    );

    // Zonas de color (con un pequeño espacio entre ellas).
    for (var i = 0; i < zoneColors.length; i++) {
      final start = _zoneStops[i];
      final end = _zoneStops[i + 1];
      final active = fraction >= start;
      canvas.drawArc(
        rect,
        math.pi + start * math.pi + 0.012,
        (end - start) * math.pi - 0.024,
        false,
        Paint()
          ..color = active ? zoneColors[i] : zoneColors[i].withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // Marcas y etiquetas cada potencia de 10.
    for (var i = 0; i < _tickLabels.length; i++) {
      final t = i / (_tickLabels.length - 1);
      final angle = math.pi + t * math.pi;
      final dir = Offset(math.cos(angle), math.sin(angle));

      canvas.drawLine(
        center + dir * (radius - stroke / 2 - 4),
        center + dir * (radius - stroke / 2 - 12),
        Paint()
          ..color = needleColor.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );

      final tp = TextPainter(
        text: TextSpan(text: _tickLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = center + dir * (radius + stroke / 2 + 14);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Aguja con brillo en la punta.
    final needleAngle = math.pi + fraction * math.pi;
    final needleDir = Offset(math.cos(needleAngle), math.sin(needleAngle));
    final tip = center + needleDir * (radius - stroke - 10);

    canvas.drawCircle(
      tip,
      10,
      Paint()
        ..color = _colorAt(fraction).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 9, Paint()..color = needleColor);
    canvas.drawCircle(center, 4, Paint()..color = _colorAt(fraction));
  }

  Color _colorAt(double f) {
    for (var i = zoneColors.length - 1; i >= 0; i--) {
      if (f >= _zoneStops[i]) return zoneColors[i];
    }
    return zoneColors.first;
  }

  @override
  bool shouldRepaint(covariant _LuxGaugePainter old) =>
      old.fraction != fraction ||
      old.needleColor != needleColor ||
      old.trackColor != trackColor;
}
