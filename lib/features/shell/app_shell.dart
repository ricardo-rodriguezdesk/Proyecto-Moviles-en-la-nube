import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/offline_banner.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Inicio', Icons.home_outlined, Icons.home),
  _Destination('Catálogo', Icons.local_florist_outlined, Icons.local_florist),
  _Destination('Luz', Icons.wb_sunny_outlined, Icons.wb_sunny),
  _Destination('Perfil', Icons.person_outline, Icons.person),
];

/// Estructura principal con navegación entre las 4 secciones.
///
/// Diseño responsivo:
///  - Celular (< 720 px de ancho): barra de navegación inferior.
///  - Tablet / escritorio (≥ 720 px): barra lateral (NavigationRail).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      // Tocar la pestaña actual regresa a su pantalla inicial.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;

        if (wide) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: Row(
              children: [
                // En horizontal la pantalla es baja: la barra lateral puede
                // hacer scroll y el logo se oculta para que no se desborde.
                LayoutBuilder(
                  builder: (context, railConstraints) {
                    final tall = railConstraints.maxHeight >= 480;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: railConstraints.maxHeight),
                        child: IntrinsicHeight(
                          child: NavigationRail(
                            selectedIndex: navigationShell.currentIndex,
                            onDestinationSelected: _onSelect,
                            labelType: NavigationRailLabelType.all,
                            groupAlignment: tall ? -1 : 0,
                            leading: tall
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Icon(Icons.eco,
                                        size: 32, color: scheme.primary),
                                  )
                                : null,
                            destinations: [
                              for (final d in _destinations)
                                NavigationRailDestination(
                                  icon: Icon(d.icon),
                                  selectedIcon: Icon(d.selectedIcon),
                                  label: Text(d.label),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: navigationShell),
                      const OfflineBanner(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OfflineBanner(),
              NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onSelect,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
