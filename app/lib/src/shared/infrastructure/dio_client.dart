import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../presentation/localization/app_localizations.dart';

class DioClient {
  late final Dio _dio;
  String? _playerID;
  String? _hostID;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': AppLocalizationUtils.currentDeviceLanguageCode(),
        },
      ),
    );

    // Interceptor to add custom headers dynamically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_playerID != null) {
            options.headers['X-Player-ID'] = _playerID;
          }
          if (_hostID != null) {
            options.headers['X-Host-ID'] = _hostID;
          }
          options.headers['Accept-Language'] =
              AppLocalizationUtils.currentDeviceLanguageCode();
          return handler.next(options);
        },
      ),
    );

    // Add logging in debug mode
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  void setPlayerID(String? id) => _playerID = id;
  void setHostID(String? id) => _hostID = id;

  Dio get instance => _dio;
}
