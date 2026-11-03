import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/onboarding_provider.dart';
import 'providers/session_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        // Servicios (no cambian, no notifican).
        Provider<AuthService>.value(value: authService),

        // Estado global.
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => OnboardingProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SessionProvider(authService)),

        // El router depende de la sesión y del onboarding.
        Provider<GoRouter>(
          create: (ctx) => createRouter(
            session: ctx.read<SessionProvider>(),
            onboarding: ctx.read<OnboardingProvider>(),
          ),
          dispose: (_, router) => router.dispose(),
        ),
      ],
      child: const LumenApp(),
    ),
  );
}
