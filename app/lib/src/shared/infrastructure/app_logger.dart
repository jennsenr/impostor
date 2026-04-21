import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class AppLogger {
  static void info(String message) {
    if (!AppConfig.isProduction || kDebugMode) {
      debugPrint(message);
    }
  }

  static void error(String message, [Object? error]) {
    if (!AppConfig.isProduction || kDebugMode) {
      final suffix = error == null ? '' : ': $error';
      debugPrint('$message$suffix');
    }
  }
}
