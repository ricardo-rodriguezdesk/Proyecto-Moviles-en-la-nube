import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';

/// Rutas de la app. Aquí agregaremos onboarding, login, perfil, mapa, pagos...
/// y la redirección según si el usuario inició sesión y verificó su correo.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
