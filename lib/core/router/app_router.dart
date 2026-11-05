import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/catalog/plant_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/light/light_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/session_provider.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Rutas de la app.
///
/// - Las 4 secciones principales (Inicio, Catálogo, Luz, Perfil) viven en un
///   StatefulShellRoute: comparten la barra de navegación y cada una
///   conserva su estado al cambiar de pestaña.
/// - Detalle de planta y notificaciones se abren encima, a pantalla completa.
/// - El router escucha la sesión y el onboarding para redirigir solo.
GoRouter createRouter({
  required SessionProvider session,
  required OnboardingProvider onboarding,
}) {
  const authRoutes = {'/login', '/register', '/forgot'};

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    refreshListenable: Listenable.merge([session, onboarding]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 1. Primero el onboarding (solo la primera vez).
      if (!onboarding.seen) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // 2. Sin sesión: solo pantallas de autenticación.
      if (!session.isLoggedIn) {
        return authRoutes.contains(loc) ? null : '/login';
      }

      // 3. Cuenta de correo sin verificar: solo la pantalla de verificación.
      if (session.needsVerification) {
        return loc == '/verify' ? null : '/verify';
      }

      // 4. Con sesión lista: no tiene sentido volver a login/onboarding.
      if (authRoutes.contains(loc) ||
          loc == '/verify' ||
          loc == '/onboarding') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/home'),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/verify', builder: (_, __) => const VerifyEmailScreen()),

      // ---------- Secciones con barra de navegación ----------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/catalog', builder: (_, __) => const CatalogScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/light', builder: (_, __) => const LightScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // ---------- Pantallas completas (encima de la barra) ----------
      GoRoute(
        path: '/plant/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            PlantDetailScreen(plantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
  );
}
