import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/app_keys.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

class LumenApp extends StatelessWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp.router(
      title: 'Lumen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // Scroll con rebote suave (estilo iPhone) en toda la app, en lugar
      // del efecto de "estirar" de Android 12+.
      scrollBehavior: const _LumenScrollBehavior(),
      // Permite que el listener global de notificaciones muestre avisos
      // en cualquier pantalla.
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: context.read<GoRouter>(),
    );
  }
}

class _LumenScrollBehavior extends MaterialScrollBehavior {
  const _LumenScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  // Con rebote no hace falta el indicador de fin de lista.
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
