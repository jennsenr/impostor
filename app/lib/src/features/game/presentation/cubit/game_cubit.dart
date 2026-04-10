import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/models/ws_event.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../../shared/infrastructure/websocket_service.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final GameRepository _repository;
  final WebSocketService _wsService;
  StreamSubscription? _subscription;
  StreamSubscription? _statusSubscription;
  bool _isRefreshingFinalGame = false;
  Timer? _nextRoundTimer;

  GameCubit(this._repository, this._wsService, String playerID)
      : super(GameState(status: GameInitial(), myPlayerId: playerID));

  String _errorCode(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  void _emitTransientError(String code) {
    if (isClosed) return;
    emit(state.copyWith(transientError: code));
    emit(state.copyWith(clearTransientError: true));
  }

  void init(Game game) {
    _emitLoadedGame(game);
    _refreshFinishedGameIfNeeded(game);
    
    // El weblink ya debería estar conectado desde el Lobby, pero nos aseguramos
    // en caso de navegación directa o reconexión.
    _wsService.connect(game.id, state.myPlayerId);
    
    _subscription = _wsService.eventStream.listen((event) {
      if (isClosed) return;
      if (event.type == WebSocketEventType.gameUpdate && event.game != null) {
         _emitLoadedGame(event.game!);
         _refreshFinishedGameIfNeeded(event.game!);
         emit(state.copyWith(lastEvent: event));
      } else if (event.type == WebSocketEventType.playerEvent) {
         emit(state.copyWith(lastEvent: event));
      }
    });

    _statusSubscription = _wsService.statusStream.listen((status) async {
      if (status == WebSocketStatus.disconnected) {
        final currentStatus = state.status;
        if (currentStatus is GameLoaded) {
          try {
            await _repository.getGame(currentStatus.game.id);
          } catch (e) {
            // Se produjo una excepción de 404/game_not_found
            if (!isClosed && (e.toString().contains('404') || e.toString().contains('game_not_found'))) {
              emit(state.copyWith(status: GameDeleted()));
            }
          }
        }
      }
    });
  }

  void _emitLoadedGame(Game game) {
    if (isClosed) return;
    final me = game.getMe(state.myPlayerId);
    emit(
      state.copyWith(
        status: GameLoaded(game),
        isReady: me?.isReady ?? false,
      ),
    );

    // Auto-advance logic for Host on intermediate results (Ties or Expulsions)
    if (game.status == GameStatus.result && game.hostId == state.myPlayerId && game.winnerTeam == null) {
      _startNextRoundTimer(game.id);
    } else {
      _nextRoundTimer?.cancel();
      _nextRoundTimer = null;
    }
  }

  void _startNextRoundTimer(String gameId) {
    if (_nextRoundTimer != null) return;
    
    _nextRoundTimer = Timer(const Duration(seconds: 4), () {
      nextRound();
    });
  }

  Future<void> _refreshFinishedGameIfNeeded(Game game) async {
    final shouldRefresh =
        game.status == GameStatus.finished &&
        game.word.trim().isEmpty &&
        !_isRefreshingFinalGame;

    if (!shouldRefresh) return;

    _isRefreshingFinalGame = true;
    try {
      final refreshedGame = await _repository.getGame(game.id);
      if (!isClosed) {
        _emitLoadedGame(refreshedGame);
      }
    } catch (_) {
      // Si el refresco falla, mantenemos el estado recibido por WebSocket.
    } finally {
      _isRefreshingFinalGame = false;
    }
  }

  Future<void> ready() async {
    final status = state.status;
    if (status is! GameLoaded) return;
    
    try {
      await _repository.readyPlayer(status.game.id, state.myPlayerId);
      emit(state.copyWith(isReady: true));
    } catch (error) {
      _emitTransientError(_errorCode(error, 'ready_failed'));
    }
  }

  Future<void> nextTurn() async {
    final status = state.status;
    if (status is! GameLoaded) return;
    
    try {
      await _repository.nextTurn(status.game.id, state.myPlayerId);
    } catch (error) {
      _emitTransientError(_errorCode(error, 'next_turn_failed'));
    }
  }

  Future<void> vote(String targetId) async {
    final status = state.status;
    if (status is! GameLoaded) return;
    
    try {
      await _repository.submitVote(
        gameId: status.game.id,
        voterId: state.myPlayerId,
        targetId: targetId,
      );
    } catch (error) {
      _emitTransientError(_errorCode(error, 'vote_failed'));
    }
  }

  Future<void> decide(bool voteToVoting) async {
    final status = state.status;
    if (status is! GameLoaded) return;
    
    try {
      await _repository.submitDecision(
        gameId: status.game.id,
        playerId: state.myPlayerId,
        voteToVoting: voteToVoting,
      );
    } catch (error) {
      _emitTransientError(_errorCode(error, 'decision_failed'));
    }
  }
  
  Future<void> finishAd() async {
     final status = state.status;
    if (status is! GameLoaded) return;
    
    try {
      await _repository.finishAd(status.game.id, state.myPlayerId);
    } catch (error) {
      _emitTransientError(_errorCode(error, 'ad_failed'));
    }
  }

  Future<void> rematch() async {
    final status = state.status;
    if (status is! GameLoaded) return;

    try {
      await _repository.rematch(status.game.id);
      // El WS recibirá el estado actualizado automáticamente
    } catch (error) {
      _emitTransientError(_errorCode(error, 'rematch_failed'));
    }
  }

  Future<void> nextRound() async {
    final status = state.status;
    if (status is! GameLoaded) return;

    try {
      await _repository.nextRound(status.game.id, state.myPlayerId);
    } catch (error) {
      _emitTransientError(_errorCode(error, 'next_round_failed'));
    }
  }

  Future<void> leaveGame() async {
    final status = state.status;
    if (status is! GameLoaded) return;

    emit(state.copyWith(isLeaving: true));

    try {
      await _repository.leaveGame(status.game.id, state.myPlayerId);
      emit(state.copyWith(status: GameLeft()));
    } catch (_) {
      // Ignorar errores al salir, el usuario ya se va
      emit(state.copyWith(status: GameLeft()));
    } finally {
      _wsService.disconnect();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _statusSubscription?.cancel();
    _nextRoundTimer?.cancel();
    // No desconectamos el WS aquí necesariamente si queremos mantenerlo hasta el final del juego
    // pero para seguridad cerramos recursos
    return super.close();
  }
}
