import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/models/ws_event.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../../shared/infrastructure/websocket_service.dart';
import '../../../../shared/presentation/localization/app_localizations.dart';
import 'lobby_state.dart';

class LobbyCubit extends Cubit<LobbyState> {
  final GameRepository _repository;
  final WebSocketService _wsService;
  StreamSubscription? _eventSubscription;
  StreamSubscription? _statusSubscription;

  LobbyCubit(this._repository, this._wsService, String playerID)
    : super(LobbyState(status: LobbyInitial(), myPlayerId: playerID));

  String _errorCode(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  void _emitTransientError(String code) {
    if (isClosed) return;
    emit(state.copyWith(transientError: code));
    emit(state.copyWith(clearTransientError: true));
  }

  Future<void> init(Game game) async {
    emit(state.copyWith(status: LobbyLoaded(game)));

    // Fetch available categories from backend
    try {
      final categories = await _repository.getCategories();
      if (!isClosed) {
        emit(state.copyWith(availableCategories: categories));
      }
    } catch (_) {
      // Fallback or ignore
    }

    // Conectar a WebSocket para actualizaciones en tiempo real
    _wsService.connect(game.id, state.myPlayerId);

    _eventSubscription = _wsService.eventStream.listen((event) {
      if (isClosed) return;
      if (event.type == WebSocketEventType.gameUpdate && event.game != null) {
        emit(
          state.copyWith(status: LobbyLoaded(event.game!), lastEvent: event),
        );
      } else if (event.type == WebSocketEventType.playerEvent) {
        // Solo emitir si el evento es de otro jugador (opcional, pero más limpio)
        emit(state.copyWith(lastEvent: event));
      }
    });

    _statusSubscription = _wsService.statusStream.listen((status) async {
      if (isClosed) return;
      emit(state.copyWith(connectionStatus: status));

      if (status == WebSocketStatus.disconnected) {
        final currentStatus = state.status;
        if (currentStatus is LobbyLoaded) {
          try {
            await _repository.getGame(currentStatus.game.id);
            if (isClosed) return;
          } catch (e) {
            if (isClosed) return;
            // Error fetching game usually means it was deleted (404)
            if (e.toString().contains('404') ||
                e.toString().contains('game_not_found')) {
              emit(state.copyWith(status: const LobbyError('game_deleted')));
            }
          }
        }
      }
    });
  }

  void reconnect() {
    final status = state.status;
    if (status is LobbyLoaded) {
      _wsService.connect(status.game.id, state.myPlayerId);
    }
  }

  Future<void> startGame() async {
    final status = state.status;
    if (status is! LobbyLoaded) return;

    try {
      await _repository.startGame(status.game.id, state.myPlayerId);
      // El cambio de estado vendrá por WebSocket
    } catch (_) {
      _emitTransientError('start_game_failed');
    }
  }

  Future<void> updateSettings({
    List<String>? categoryIds,
    int? impostorCount,
    bool? juniorMode,
    bool? survivalMode,
    bool? questionsMode,
    bool? timerEnabled,
    int? timerSeconds,
  }) async {
    final status = state.status;
    if (status is! LobbyLoaded) return;

    final currentSettings = status.game.settings;

    try {
      await _repository.updateSettings(
        gameId: status.game.id,
        hostId: state.myPlayerId,
        categoryIds: categoryIds ?? currentSettings.categoryIds,
        language: AppLocalizationUtils.currentDeviceLanguageCode(),
        impostorCount: impostorCount ?? currentSettings.impostorCount,
        juniorMode: juniorMode ?? currentSettings.juniorMode,
        survivalMode: survivalMode ?? currentSettings.survivalMode,
        questionsMode: questionsMode ?? currentSettings.questionsMode,
        timerEnabled: timerEnabled ?? currentSettings.timerEnabled,
        timerSeconds: timerSeconds ?? currentSettings.timerSeconds,
      );
      // El cambio vendrá por WebSocket
    } catch (error) {
      _emitTransientError(_errorCode(error, 'update_settings_failed'));
    }
  }

  Future<void> finishAd() async {
    final status = state.status;
    if (status is! LobbyLoaded) return;

    try {
      await _repository.finishAd(status.game.id, state.myPlayerId);
    } catch (error) {
      _emitTransientError(_errorCode(error, 'ad_failed'));
    }
  }

  Future<void> leaveGame() async {
    final status = state.status;
    if (status is! LobbyLoaded) return;

    emit(state.copyWith(isLeaving: true));

    try {
      await _repository.leaveGame(status.game.id, state.myPlayerId);
      emit(state.copyWith(status: LobbyLeft()));
    } catch (error) {
      emit(state.copyWith(isLeaving: false));
      _emitTransientError(_errorCode(error, 'leave_game_failed'));
    }
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    _statusSubscription?.cancel();
    return super.close();
  }
}
