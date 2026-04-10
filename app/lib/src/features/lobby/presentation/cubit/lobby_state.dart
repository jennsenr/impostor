import 'package:equatable/equatable.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/models/ws_event.dart';

abstract class LobbyStatus extends Equatable {
  const LobbyStatus();
  @override
  List<Object?> get props => [];
}

class LobbyInitial extends LobbyStatus {}
class LobbyLoading extends LobbyStatus {}
class LobbyLoaded extends LobbyStatus {
  final Game game;
  const LobbyLoaded(this.game);
  @override
  List<Object?> get props => [game];
}
class LobbyLeft extends LobbyStatus {}

class LobbyError extends LobbyStatus {
  final String message;
  const LobbyError(this.message);
  @override
  List<Object?> get props => [message];
}

class LobbyState extends Equatable {
  final LobbyStatus status;
  final String myPlayerId;
  final List<Category> availableCategories; // Added dynamic categories
  final bool isLeaving;
  final WebSocketEvent? lastEvent;
  final WebSocketStatus connectionStatus;
  final String? transientError;

  const LobbyState({
    required this.status,
    required this.myPlayerId,
    this.availableCategories = const [],
    this.isLeaving = false,
    this.lastEvent,
    this.connectionStatus = WebSocketStatus.connecting,
    this.transientError,
  });

  LobbyState copyWith({
    LobbyStatus? status,
    String? myPlayerId,
    List<Category>? availableCategories,
    bool? isLeaving,
    WebSocketEvent? lastEvent,
    WebSocketStatus? connectionStatus,
    String? transientError,
    bool clearTransientError = false,
  }) {
    return LobbyState(
      status: status ?? this.status,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      availableCategories: availableCategories ?? this.availableCategories,
      isLeaving: isLeaving ?? this.isLeaving,
      lastEvent: lastEvent ?? this.lastEvent,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      transientError: clearTransientError
          ? null
          : (transientError ?? this.transientError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        myPlayerId,
        availableCategories,
        isLeaving,
        lastEvent,
        connectionStatus,
        transientError,
      ];
}
