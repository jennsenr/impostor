import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/features/setup/presentation/cubit/setup_cubit.dart';
import 'src/shared/config/app_config.dart';
import 'src/shared/infrastructure/ads_consent_service.dart';
import 'src/shared/infrastructure/ads_service.dart';
import 'src/shared/infrastructure/service_locator.dart';
import 'src/shared/infrastructure/websocket_service.dart';
import 'src/shared/presentation/localization/app_localizations.dart';
import 'src/shared/presentation/theme/app_theme.dart';
import 'src/shared/presentation/router/app_router.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de inyección de dependencias
  await initServiceLocator();
  await sl<AdsConsentService>().gatherConsent();
  await sl<AdsService>().initialize();

  runApp(
    BlocProvider(
      create: (context) => sl<SetupCubit>(),
      child: const ImpostorApp(),
    ),
  );
}

void main() async {
  AppConfig.configureFlavor(AppFlavor.dev);
  await bootstrap();
}

class ImpostorApp extends StatefulWidget {
  const ImpostorApp({super.key});

  @override
  State<ImpostorApp> createState() => _ImpostorAppState();
}

class _ImpostorAppState extends State<ImpostorApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<WebSocketService>().reconnectIfNeeded();
      sl<SetupCubit>().restorePreviousSessionOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.darkTheme,
      supportedLocales: ImpostorLocalizations.supportedLocales,
      localizationsDelegates: const [
        ImpostorLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
