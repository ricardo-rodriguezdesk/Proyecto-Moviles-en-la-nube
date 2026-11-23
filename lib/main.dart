import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_keys.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/avatar_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/notification_inbox.dart';
import 'providers/onboarding_provider.dart';
import 'providers/session_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/topics_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Notificaciones con la app en segundo plano o cerrada.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();

  // Stripe (modo prueba). Si falla, la app sigue funcionando sin pagos.
  try {
    await PaymentService.init();
  } catch (e) {
    debugPrint('[Stripe] No se pudo iniciar: $e');
  }

  // Servicios.
  final authService = AuthService();
  final firestore = FirestoreService();
  final storage = StorageService();

  // Estado global.
  final theme = ThemeProvider(prefs);
  final onboarding = OnboardingProvider(prefs);
  final session = SessionProvider(authService);
  final inbox = NotificationInbox(firestore);
  final topics = TopicsProvider(prefs);
  final catalog = CatalogProvider(firestore);
  final connectivity = ConnectivityProvider();
  final subscription = SubscriptionProvider(firestore);
  final avatar = AvatarProvider(firestore);
  final router = createRouter(session: session, onboarding: onboarding);

  // Cuando cambia la sesión: crear/actualizar el perfil en Firestore,
  // conectar la bandeja de notificaciones y el catálogo.
  String? lastUid;
  void syncSession() {
    final user = session.user;
    inbox.attachUser(user?.uid);
    subscription.attachUser(user?.uid);
    avatar.attachUser(user?.uid);
    catalog.setActive(user != null);
    if (user != null && user.uid != lastUid) {
      firestore.ensureUserDoc(user).catchError(
            (Object e) => debugPrint('[Firestore] Perfil no guardado: $e'),
          );
    }
    lastUid = user?.uid;
  }

  session.addListener(syncSession);
  syncSession();

  final notifications = NotificationService(
    router: router,
    inbox: inbox,
    topics: topics,
    messengerKey: rootMessengerKey,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<FirestoreService>.value(value: firestore),
        Provider<StorageService>.value(value: storage),
        Provider<GoRouter>.value(value: router),
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: onboarding),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: inbox),
        ChangeNotifierProvider.value(value: topics),
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: connectivity),
        ChangeNotifierProvider.value(value: subscription),
        ChangeNotifierProvider.value(value: avatar),
      ],
      child: const LumenApp(),
    ),
  );

  // Se inicia cuando ya existe la primera pantalla, para que el diálogo de
  // permiso y la navegación desde una notificación funcionen bien.
  WidgetsBinding.instance.addPostFrameCallback((_) => notifications.init());
}
