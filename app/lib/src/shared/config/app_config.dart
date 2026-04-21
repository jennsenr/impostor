import 'dart:io';

enum AppFlavor { dev, prod }

class AppConfig {
  static const String _defaultFlavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static const String _apiUrlOverride = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const String _localDevHost = 'localhost';
  static const String _androidEmulatorHost = '10.0.2.2';
  static const int _devApiPort = 8080;
  static const String _prodApiOrigin = 'https://impostor.manggio.com';
  static const String _androidProdAdMobAppId =
      'ca-app-pub-5124910666152668~8734496052';
  static const String _iosProdAdMobAppId =
      'ca-app-pub-5124910666152668~5669349010';
  static const String _androidProdInterstitialAdUnitId =
      'ca-app-pub-5124910666152668/6228599672';
  static const String _iosProdInterstitialAdUnitId =
      'ca-app-pub-5124910666152668/8351352675';
  static const String _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static AppFlavor? _runtimeFlavor;

  static void configureFlavor(AppFlavor flavor) {
    _runtimeFlavor = flavor;
  }

  static AppFlavor get currentFlavor {
    return _runtimeFlavor ?? _parseFlavor(_defaultFlavorName);
  }

  static String get flavor => currentFlavor.name;

  static bool get isProduction => flavor == 'prod';

  static AppFlavor _parseFlavor(String flavor) {
    return flavor == AppFlavor.prod.name ? AppFlavor.prod : AppFlavor.dev;
  }

  static String _resolveDefaultDevOrigin({required bool isAndroid}) {
    final host = isAndroid ? _androidEmulatorHost : _localDevHost;
    return 'http://$host:$_devApiPort';
  }

  static String resolveApiOrigin({
    required String flavor,
    String? apiUrl,
    bool isAndroid = false,
  }) {
    final configuredUrl = apiUrl?.trim() ?? '';
    var origin = configuredUrl.isNotEmpty
        ? configuredUrl
        : (flavor == AppFlavor.prod.name
              ? _prodApiOrigin
              : _resolveDefaultDevOrigin(isAndroid: isAndroid));

    origin = origin.replaceFirst(RegExp(r'/+$'), '');
    origin = origin.replaceFirst(RegExp(r'/v1$'), '');

    // Si se fuerza localhost en Android, traducirlo al host del emulador.
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

  static bool get adsEnabled => Platform.isAndroid || Platform.isIOS;

  static String get admobAppId {
    if (Platform.isAndroid) {
      return _androidProdAdMobAppId;
    }
    if (Platform.isIOS) {
      return _iosProdAdMobAppId;
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return isProduction
          ? _androidProdInterstitialAdUnitId
          : _androidTestInterstitialAdUnitId;
    }
    if (Platform.isIOS) {
      return isProduction
          ? _iosProdInterstitialAdUnitId
          : _iosTestInterstitialAdUnitId;
    }
    return '';
  }
}
