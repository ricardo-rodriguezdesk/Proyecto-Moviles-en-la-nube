import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/session_provider.dart';

/// El router escucha la sesión y el onboarding, y decide a dónde mandar
/// al usuario. Las pantallas nunca navegan "a mano" después de iniciar
/// sesión: solo cambia el estado y el router redirige.
GoRouter createRouter({
  required SessionProvider session,
  required OnboardingProvider onboarding,
}) {
  const authRoutes = {'/login', '/register', '/forgot'};

  return GoRouter(
    initialLocation: '/',
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
      if (authRoutes.contains(loc) || loc == '/verify' || loc == '/onboarding') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
}
