import 'dart:io';

class AppConfig {
  static const String _defaultUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.68.63:8080',
  );

  static String get apiBaseUrl {
    String url = _defaultUrl;
    
    // Si estamos en Android y la URL es localhost, cambiar a 10.0.2.2
    if (Platform.isAndroid && url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    
    return '$url/v1/';
  }

  static String get staticAssetsUrl {
    return apiBaseUrl.replaceAll('/v1/', '').replaceAll(RegExp(r'/$'), '');
  }

  static String get wsBaseUrl {
    String url = apiBaseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
    return url;
  }

  static String get invitationBaseUrl {
    return apiBaseUrl.replaceAll('/v1/', '/') + 'join';
  }
  
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
