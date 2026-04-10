import 'package:flutter_test/flutter_test.dart';
import 'package:impostor/src/shared/infrastructure/deep_link_service.dart';

void main() {
  late DeepLinkService deepLinkService;

  setUp(() {
    deepLinkService = DeepLinkService();
  });

  group('DeepLinkService URI Parsing', () {
    test('Should parse custom scheme with query param correctly', () async {
      final uri = Uri.parse('impostor://join?code=1234');
      
      final future = deepLinkService.codeStream.first;
      deepLinkService.handleUri(uri);
      
      final code = await future;
      expect(code, equals('1234'));
    });

    test('Should parse HTTP path-based link correctly', () async {
      final uri = Uri.parse('http://192.168.1.63:8080/join/ABCD');
      
      final future = deepLinkService.codeStream.first;
      deepLinkService.handleUri(uri);
      
      final code = await future;
      expect(code, equals('ABCD'));
    });

    test('Should parse HTTP query-based link correctly', () async {
      final uri = Uri.parse('http://192.168.1.63:8080/join?code=QWER');
      
      final future = deepLinkService.codeStream.first;
      deepLinkService.handleUri(uri);
      
      final code = await future;
      expect(code, equals('QWER'));
    });

    test('Should ignore invalid paths', () async {
      final uri = Uri.parse('http://192.168.1.63:8080/other/1234');
      
      bool received = false;
      deepLinkService.codeStream.listen((_) => received = true);
      
      deepLinkService.handleUri(uri);
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(received, isFalse);
    });
  });
}
