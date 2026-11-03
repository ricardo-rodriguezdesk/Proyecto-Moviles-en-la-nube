import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema de Lumen: verdes de vivero + tipografías personalizadas.
/// - Fraunces (serif) para títulos.
/// - Inter (sans) para el texto general.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF2E7D4F); // verde hoja

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );

    // Aplicamos las fuentes estilo por estilo (TextStyle) en lugar de usar
    // GoogleFonts.interTextTheme, que en esta versión choca con el TextTheme
    // de Flutter (google_fonts 9 usa el paquete material_ui).
    final t = base.textTheme;
    TextStyle? sans(TextStyle? s) => GoogleFonts.inter(textStyle: s);
    TextStyle? serif(TextStyle? s) => GoogleFonts.fraunces(textStyle: s);

    final textTheme = TextTheme(
      displayLarge: serif(t.displayLarge),
      displayMedium: serif(t.displayMedium),
      displaySmall: serif(t.displaySmall),
      headlineLarge: serif(t.headlineLarge),
      headlineMedium: serif(t.headlineMedium),
      headlineSmall: serif(t.headlineSmall),
      titleLarge: serif(t.titleLarge)?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: sans(t.titleMedium),
      titleSmall: sans(t.titleSmall),
      bodyLarge: sans(t.bodyLarge),
      bodyMedium: sans(t.bodyMedium),
      bodySmall: sans(t.bodySmall),
      labelLarge: sans(t.labelLarge),
      labelMedium: sans(t.labelMedium),
      labelSmall: sans(t.labelSmall),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
