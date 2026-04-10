import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../../shared/infrastructure/service_locator.dart';
import '../../../../shared/infrastructure/deep_link_service.dart';
import 'setup_state.dart';

class SetupCubit extends Cubit<SetupState> {
  final GameRepository _repository;
  final DeepLinkService _deepLinkService;

  SetupCubit(this._repository, this._deepLinkService)
      : super(const SetupState(status: SetupInitial())) {
    loadCategories();
    _initDeepLinks();
  }

  String _normalizeErrorCode(Object error, String fallback) {
    final code = error.toString().replaceAll('Exception: ', '').trim();
    const knownCodes = {
      'name_already_taken',
      'avatar_already_taken',
      'game_not_found',
      'join_game_failed',
      'create_game_failed',
      'fetch_categories_failed',
      'invalid_game_status',
      'not_host',
      'invalid_category',
      'game_full',
    };
    if (knownCodes.contains(code)) return code;
    return fallback;
  }

  void _initDeepLinks() {
    _deepLinkService.codeStream.listen((code) {
      if (code.isNotEmpty) {
        startJoiningWithCode(code);
      }
    });
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _repository.getCategories();
      final prefs = sl<SharedPreferences>();
      
      // Load saved preferences
      final savedName = prefs.getString('pref_player_name') ?? '';
      final savedJunior = prefs.getBool('pref_junior_mode') ?? false;
      final savedCategoryIds = prefs.getStringList('pref_selected_category_ids') ?? ['animals'];

      // Filter category IDs that might no longer exist
      final validCategoryIds = savedCategoryIds.where((id) => categories.any((c) => c.id == id)).toList();
      
      emit(state.copyWith(
        categories: categories,
        playerName: savedName,
        avatarId: '', // Always start with no avatar selected
        juniorMode: savedJunior,
        selectedCategoryIds: validCategoryIds.isEmpty && categories.isNotEmpty ? [categories.first.id] : validCategoryIds,
      ));
    } catch (e) {
      emit(state.copyWith(status: const SetupError('fetch_categories_failed')));
    }
  }

  void updateName(String name) {
    emit(state.copyWith(playerName: name));
    sl<SharedPreferences>().setString('pref_player_name', name);
  }

  void updateAvatar(String avatarId) {
    final newId = state.avatarId == avatarId ? '' : avatarId;
    emit(state.copyWith(avatarId: newId));
    sl<SharedPreferences>().setString('pref_avatar_id', newId);
  }

  void updateIsCreating(bool value) {
    emit(state.copyWith(
      isCreating: value,
      pendingGameId: value ? null : state.pendingGameId, // Clear if starting creation
      occupiedAvatarIds: value ? [] : state.occupiedAvatarIds,
    ));
  }

  void proceedToProfileSelection() {
    emit(state.copyWith(status: const SetupProfileSelection()));
  }

  void backToSettings() async {
    final currentStatus = state.status;
    if (currentStatus is SetupSuccess) {
      try {
        await _repository.leaveGame(currentStatus.game.id, currentStatus.playerId);
      } catch (_) {}
    }
    emit(state.copyWith(
      status: const SetupInitial(),
      clearPendingGameId: true,
      occupiedAvatarIds: [],
    ));
  }

  void updateGame(Game game) {
    final currentStatus = state.status;
    if (currentStatus is SetupSuccess) {
      emit(state.copyWith(
        status: SetupSuccess(game, currentStatus.playerId),
      ));
    }
  }

  void backToProfile() async {
    // This allows going back from Lobby to Profile Selection
    emit(state.copyWith(status: const SetupProfileSelection()));
  }

  void toggleCategory(String categoryId) {
    final ids = List<String>.from(state.selectedCategoryIds);
    if (ids.contains(categoryId)) {
      if (ids.length > 1) { // Prevent zero categories selected
        ids.remove(categoryId);
      }
    } else {
      ids.add(categoryId);
    }
    emit(state.copyWith(selectedCategoryIds: ids));
    sl<SharedPreferences>().setStringList('pref_selected_category_ids', ids);
  }
  
  void toggleJunior(bool value) {
    List<String> selectedIds = List<String>.from(state.selectedCategoryIds);
    
    if (value) {
      selectedIds = selectedIds.where((id) {
        final category = state.categories.firstWhere((c) => c.id == id);
        return category.isJuniorAvailable;
      }).toList();

      if (selectedIds.isEmpty && state.categories.isNotEmpty) {
        try {
          final firstValid = state.categories.firstWhere((c) => c.isJuniorAvailable);
          selectedIds = [firstValid.id];
        } catch (_) {}
      }
    }
    
    emit(state.copyWith(juniorMode: value, selectedCategoryIds: selectedIds));
    sl<SharedPreferences>().setBool('pref_junior_mode', value);
    sl<SharedPreferences>().setStringList('pref_selected_category_ids', selectedIds);
  }

  void toggleSurvival(bool value) {
    emit(state.copyWith(survivalMode: value));
  }

  void toggleTimer(bool value) {
    emit(state.copyWith(timerEnabled: value));
  }

  void setTimerSeconds(int seconds) {
    emit(state.copyWith(timerSeconds: seconds));
  }

  Future<void> createGame() async {
    if (state.playerName.isEmpty) {
      emit(state.copyWith(status: const SetupError('name_required')));
      return;
    }

    if (state.selectedCategoryIds.isEmpty) {
      emit(state.copyWith(status: const SetupError('category_required')));
      return;
    }

    emit(state.copyWith(status: SetupLoading()));
    try {
      final response = await _repository.createGame(
        hostName: state.playerName,
        avatarId: state.avatarId,
        categories: state.selectedCategoryIds,
        juniorMode: state.juniorMode,
        survivalMode: state.survivalMode,
        timerEnabled: state.timerEnabled,
        timerSeconds: state.timerSeconds,
      );
      emit(state.copyWith(status: SetupSuccess(response.game, response.playerId), clearPendingGameId: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: SetupError(_normalizeErrorCode(e, 'create_game_failed')),
        ),
      );
    }
  }

  Future<void> joinGame(String gameId) async {
    if (state.playerName.isEmpty) {
      emit(state.copyWith(status: const SetupError('name_required')));
      return;
    }

    emit(state.copyWith(status: SetupLoading(), clearPendingGameId: true));
    try {
      final response = await _repository.joinGame(
        gameId: gameId,
        playerName: state.playerName,
        avatarId: state.avatarId,
      );
      emit(state.copyWith(status: SetupSuccess(response.game, response.playerId), clearPendingGameId: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: SetupError(_normalizeErrorCode(e, 'join_game_failed')),
        ),
      );
    }
  }

  Future<void> rejoinGame(String gameCode) async {
    emit(state.copyWith(status: const SetupLoading()));
    try {
      final response = await _repository.joinGame(
        gameId: gameCode,
        playerName: state.playerName,
        avatarId: state.avatarId,
      );
      emit(state.copyWith(status: SetupSuccess(response.game, response.playerId), clearPendingGameId: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: SetupError(_normalizeErrorCode(e, 'join_game_failed')),
        ),
      );
    }
  }

  Future<void> startJoiningWithCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    emit(state.copyWith(status: const SetupLoading()));
    try {
      final game = await _repository.getGame(cleanCode);
      final occupiedIds = game.players.map((p) => p.avatarId).toList();

      // If current avatar is taken, clear it
      String nextAvatar = state.avatarId;
      if (occupiedIds.contains(nextAvatar)) {
        nextAvatar = '';
      }

      emit(state.copyWith(
        pendingGameId: cleanCode,
        isCreating: false,
        occupiedAvatarIds: occupiedIds,
        avatarId: nextAvatar,
        status: const SetupProfileSelection(),
      ));
    } catch (e) {
      emit(
        state.copyWith(
          status: SetupError(_normalizeErrorCode(e, 'join_game_failed')),
        ),
      );
    }
  }

  void clearPendingCode() {
    emit(state.copyWith(clearPendingGameId: true));
  }
}
