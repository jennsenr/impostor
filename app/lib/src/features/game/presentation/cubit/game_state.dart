import 'package:equatable/equatable.dart';
import '../../../../domain/models/game.dart';

import '../../../../domain/models/ws_event.dart';

abstract class GameStatusState extends Equatable {
  const GameStatusState();
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameStatusState {}
class GameLoading extends GameStatusState {}
class GameLoaded extends GameStatusState {
  final Game game;
  const GameLoaded(this.game);
  @override
  List<Object?> get props => [game];
}
class GameError extends GameStatusState {
  final String message;
  const GameError(this.message);
  @override
  List<Object?> get props => [message];
}

class GameDeleted extends GameStatusState {}
class GameLeft extends GameStatusState {}

class GameState extends Equatable {
  final GameStatusState status;
  final String myPlayerId;
  final bool isReady;
  final bool isLeaving;
  final WebSocketEvent? lastEvent;
  final String? transientError;

  const GameState({
    required this.status,
    required this.myPlayerId,
    this.isReady = false,
    this.isLeaving = false,
    this.lastEvent,
    this.transientError,
  });

  GameState copyWith({
    GameStatusState? status,
    String? myPlayerId,
    bool? isReady,
    bool? isLeaving,
    WebSocketEvent? lastEvent,
    String? transientError,
    bool clearTransientError = false,
  }) {
    return GameState(
      status: status ?? this.status,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      isReady: isReady ?? this.isReady,
      isLeaving: isLeaving ?? this.isLeaving,
      lastEvent: lastEvent ?? this.lastEvent,
      transientError: clearTransientError
          ? null
          : (transientError ?? this.transientError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        myPlayerId,
        isReady,
        isLeaving,
        lastEvent,
        transientError,
      ];
}
