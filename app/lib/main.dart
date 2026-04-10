import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'src/features/setup/presentation/cubit/setup_cubit.dart';
import 'src/shared/infrastructure/service_locator.dart';
import 'src/shared/presentation/theme/app_theme.dart';
import 'src/shared/presentation/router/app_router.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de inyección de dependencias
  await initServiceLocator();

  runApp(
    BlocProvider(
      create: (context) => sl<SetupCubit>(),
      child: const ImpostorApp(),
    ),
  );
}

void main() async {
  await bootstrap();
}

class ImpostorApp extends StatelessWidget {
  const ImpostorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      title: 'Impostor Game',
      theme: AppTheme.darkTheme,
    );
  }
}
