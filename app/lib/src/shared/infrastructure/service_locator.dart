import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/game_repository.dart';
import '../../infrastructure/repositories/api_game_repository.dart';
import 'dio_client.dart';
import 'ads_service.dart';
import 'ads_consent_service.dart';
import 'app_logger.dart';
import 'websocket_service.dart';
import 'deep_link_service.dart';
import '../../features/setup/presentation/cubit/setup_cubit.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Core
  final dioClient = DioClient();
  sl.registerSingleton<DioClient>(dioClient);
  sl.registerSingleton<AdsConsentService>(AdsConsentService());
  sl.registerLazySingleton<AdsService>(
    () => AdsService(sl<AdsConsentService>()),
  );
  sl.registerSingleton<AppLogger>(AppLogger());
  sl.registerLazySingleton<WebSocketService>(() => WebSocketService());
  sl.registerSingleton<DeepLinkService>(DeepLinkService()..init());

  // Repositories
  sl.registerLazySingleton<GameRepository>(
    () => ApiGameRepository(sl<DioClient>()),
  );

  // Cubits
  sl.registerLazySingleton<SetupCubit>(
    () => SetupCubit(sl<GameRepository>(), sl<DeepLinkService>()),
  );
}
