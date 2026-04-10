import 'package:flutter_test/flutter_test.dart';
import 'package:impostor/src/shared/config/app_config.dart';

void main() {
  group('AppConfig.resolveApiOrigin', () {
    test('uses prod domain for prod flavor by default', () {
      final origin = AppConfig.resolveApiOrigin(flavor: 'prod');

      expect(origin, 'https://impostor.manggio.com');
    });

    test('uses dev origin for dev flavor by default', () {
      final origin = AppConfig.resolveApiOrigin(flavor: 'dev');

      expect(origin, 'http://192.168.68.63:8080');
    });

    test('normalizes trailing slash and v1 suffix', () {
      final origin = AppConfig.resolveApiOrigin(
        flavor: 'prod',
        apiUrl: 'https://impostor.manggio.com/v1/',
      );

      expect(origin, 'https://impostor.manggio.com');
    });

    test('rewrites localhost for Android emulator', () {
      final origin = AppConfig.resolveApiOrigin(
        flavor: 'dev',
        apiUrl: 'http://localhost:8080',
        isAndroid: true,
      );

      expect(origin, 'http://10.0.2.2:8080');
    });
  });
}
