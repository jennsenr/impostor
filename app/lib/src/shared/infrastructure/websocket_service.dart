import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../domain/models/game.dart';
import '../../domain/models/ws_event.dart';
import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _eventStreamController = StreamController<WebSocketEvent>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  
  WebSocketStatus _currentStatus = WebSocketStatus.disconnected;
  Timer? _reconnectTimer;
  String? _lastGameID;
  String? _lastPlayerID;
  bool _isManualDisconnect = false;

  Stream<WebSocketEvent> get eventStream => _eventStreamController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  WebSocketStatus get currentStatus => _currentStatus;
  
  Stream<Game> get gameStream => _eventStreamController.stream
      .where((event) => event.type == WebSocketEventType.gameUpdate && event.game != null)
      .map((event) => event.game!);

  void _updateStatus(WebSocketStatus status) {
    if (_currentStatus == status) return;
    _currentStatus = status;
    _statusController.add(status);
    print('WebSocket Status: $status');
  }

  void connect(String gameID, String playerID) {
    _isManualDisconnect = false;
    _lastGameID = gameID;
    _lastPlayerID = playerID;

    if (_channel != null && _currentStatus == WebSocketStatus.connected) return;
    
    _reconnectTimer?.cancel();
    _updateStatus(WebSocketStatus.connecting);
    
    final uri = Uri.parse('${AppConfig.wsBaseUrl}games/$gameID/ws?player_id=$playerID');
    
    try {
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (data) {
          _updateStatus(WebSocketStatus.connected);
          if (data is String) {
            try {
              final Map<String, dynamic> json = jsonDecode(data);
              if (!json.containsKey('type')) {
                final game = Game.fromJson(json);
                _eventStreamController.add(WebSocketEvent(
                  type: WebSocketEventType.gameUpdate,
                  game: game,
                ));
                return;
              }
              final event = WebSocketEvent.fromJson(json);
              _eventStreamController.add(event);
            } catch (e) {
              print('Error parsing WS event: $e');
            }
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket Done (Closed)');
          _handleDisconnect();
        },
      );
    } catch (e) {
      print('WebSocket Connection Error: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _channel = null;
    _updateStatus(WebSocketStatus.disconnected);
    
    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_lastGameID != null && _lastPlayerID != null && !_isManualDisconnect) {
        print('Attempting auto-reconnect...');
        connect(_lastGameID!, _lastPlayerID!);
      }
    });
  }

  void disconnect() {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateStatus(WebSocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _eventStreamController.close();
    _statusController.close();
  }
}
