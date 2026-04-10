import '../../domain/models/game.dart';

enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
}

enum WebSocketEventType {
  gameUpdate,
  playerEvent,
  unknown;

  static WebSocketEventType fromString(String type) {
    switch (type) {
      case 'GAME_UPDATE': return WebSocketEventType.gameUpdate;
      case 'PLAYER_EVENT': return WebSocketEventType.playerEvent;
      default: return WebSocketEventType.unknown;
    }
  }
}

enum PlayerEvent {
  left,
  joined,
  disconnected,
  reconnected,
  unknown;

  static PlayerEvent fromString(String event) {
    switch (event) {
      case 'LEFT': return PlayerEvent.left;
      case 'JOINED': return PlayerEvent.joined;
      case 'DISCONNECTED': return PlayerEvent.disconnected;
      case 'RECONNECTED': return PlayerEvent.reconnected;
      default: return PlayerEvent.unknown;
    }
  }
}

class WebSocketEvent {
  final WebSocketEventType type;
  final Game? game;
  final PlayerEvent? event;
  final String? playerName;
  final String? avatarID;
  final String? playerID;

  WebSocketEvent({
    required this.type,
    this.game,
    this.event,
    this.playerName,
    this.avatarID,
    this.playerID,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'UNKNOWN';
    final type = WebSocketEventType.fromString(typeStr);

    if (type == WebSocketEventType.gameUpdate) {
      return WebSocketEvent(
        type: type,
        game: Game.fromJson(json['payload'] as Map<String, dynamic>),
      );
    } else if (type == WebSocketEventType.playerEvent) {
      return WebSocketEvent(
        type: type,
        event: PlayerEvent.fromString(json['event'] as String? ?? ''),
        playerName: json['name'] as String?,
        avatarID: json['avatar_id'] as String?,
        playerID: json['player_id'] as String?,
      );
    }

    return WebSocketEvent(type: WebSocketEventType.unknown);
  }
}
