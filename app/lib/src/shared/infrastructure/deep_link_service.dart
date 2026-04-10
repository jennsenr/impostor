import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  final _codeController = StreamController<String>.broadcast();
  Stream<String> get codeStream => _codeController.stream;

  void init() {
    // Escuchar links cuando la app ya está abierta
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      handleUri(uri);
    });

    // Revisar si la app se abrió inicialmente por un link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) handleUri(uri);
    });
  }

  void handleUri(Uri uri) {
    // Soportar tanto impostor://join?code=XYZ como http://<ip>/join/XYZ o /join?code=XYZ
    final String path = uri.path;
    final String host = uri.host;
    
    if (host == 'join' || path.contains('/join')) {
      String? code = uri.queryParameters['code'];
      
      // Si no está en query params, intentar sacarlo del path /join/XXXX
      if (code == null && path.contains('/join/')) {
        final segments = path.split('/');
        final joinIndex = segments.indexOf('join');
        if (joinIndex != -1 && joinIndex + 1 < segments.length) {
          code = segments[joinIndex + 1];
        }
      }
      
      if (code != null && code.isNotEmpty) {
        _codeController.add(code);
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _codeController.close();
  }
}
