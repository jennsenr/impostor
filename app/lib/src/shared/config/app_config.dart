import 'dart:io';

class AppConfig {
  static const String _defaultFlavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static const String _apiUrlOverride = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const String _devApiOrigin = 'http://192.168.68.63:8080';
  static const String _prodApiOrigin = 'https://impostor.manggio.com';

  static String get flavor => _defaultFlavor;

  static bool get isProduction => flavor == 'prod';

  static String resolveApiOrigin({
    required String flavor,
    String? apiUrl,
    bool isAndroid = false,
  }) {
    final configuredUrl = apiUrl?.trim() ?? '';
    var origin = configuredUrl.isNotEmpty
        ? configuredUrl
        : (flavor == 'prod' ? _prodApiOrigin : _devApiOrigin);

    origin = origin.replaceFirst(RegExp(r'/+$'), '');
    origin = origin.replaceFirst(RegExp(r'/v1$'), '');

    // Si estamos en Android y la URL es localhost, cambiar a 10.0.2.2
    if (isAndroid && origin.contains('localhost')) {
      origin = origin.replaceAll('localhost', '10.0.2.2');
    }

    return origin;
  }

  static String get _apiOrigin => resolveApiOrigin(
    flavor: flavor,
    apiUrl: _apiUrlOverride,
    isAndroid: Platform.isAndroid,
  );

  static String get apiBaseUrl {
    return '$_apiOrigin/v1/';
  }

  static String get staticAssetsUrl {
    return _apiOrigin;
  }

  static String get wsBaseUrl {
    final url = apiBaseUrl
        .replaceAll('http://', 'ws://')
        .replaceAll('https://', 'wss://');
    return url;
  }

  static String get invitationBaseUrl {
    return '$_apiOrigin/join';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
