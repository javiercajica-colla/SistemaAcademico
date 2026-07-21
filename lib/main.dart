import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/academic_provider.dart';
import 'providers/email_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs "limpias" en la web (sin '#') — usePathUrlStrategy() es un no-op
  // seguro en Android/iOS (implementación condicional del propio paquete),
  // así que no hace falta un guard de kIsWeb.
  usePathUrlStrategy();
  // Con useMockData = true (lib/core/config/app_config.dart) la app corre 100%
  // offline con datos falsos, así que ni siquiera se conecta a Firebase.
  if (!useMockData) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Algunas redes corporativas/VPNs bloquean el canal de streaming
    // (WebChannel) que usa Firestore por defecto en web, causando
    // "client is offline". Forzar long-polling evita ese bloqueo.
    FirebaseFirestore.instance.settings = const Settings(
      webExperimentalForceLongPolling: true,
    );
  }
  runApp(const SistemaAcademicoApp());
}

class SistemaAcademicoApp extends StatelessWidget {
  const SistemaAcademicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AcademicProvider()),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
      ],
      child: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = createRouter(auth);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduGestión Pro — Sistema Académico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
