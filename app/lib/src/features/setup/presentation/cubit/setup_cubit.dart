import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../../shared/infrastructure/service_locator.dart';
import '../../../../shared/infrastructure/deep_link_service.dart';
import '../../../../shared/presentation/localization/app_localizations.dart';
import 'setup_state.dart';

class SetupCubit extends Cubit<SetupState> {
  static const _prefPlayerName = 'pref_player_name';
  static const _prefAvatarId = 'pref_avatar_id';
  static const _prefJuniorMode = 'pref_junior_mode';
  static const _prefImpostorCount = 'pref_impostor_count';
  static const _prefSelectedCategoryIds = 'pref_selected_category_ids';
  static const _prefSessionGameCode = 'pref_session_game_code';
  static const _prefSessionPlayerId = 'pref_session_player_id';
  static const _prefSessionPlayerName = 'pref_session_player_name';
  static const _prefSessionAvatarId = 'pref_session_avatar_id';

  final GameRepository _repository;
  final DeepLinkService _deepLinkService;
  bool _hasAttemptedStartupRestore = false;
  bool _isRestoringSession = false;

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
      'minimum_players_required',
      'session_restore_failed',
    };
    if (knownCodes.contains(code)) return code;
    return fallback;
  }

  SharedPreferences get _prefs => sl<SharedPreferences>();

  Future<void> _persistActiveSession(Game game, String playerId) async {
    final me = game.getMe(playerId);
    await _prefs.setString(_prefSessionGameCode, game.code);
    await _prefs.setString(_prefSessionPlayerId, playerId);
    await _prefs.setString(
      _prefSessionPlayerName,
      me?.name ?? state.playerName,
    );
    await _prefs.setString(
      _prefSessionAvatarId,
      me?.avatarId ?? state.avatarId,
    );
  }

  Future<void> _clearActiveSession() async {
    await _prefs.remove(_prefSessionGameCode);
    await _prefs.remove(_prefSessionPlayerId);
    await _prefs.remove(_prefSessionPlayerName);
    await _prefs.remove(_prefSessionAvatarId);
  }

  Future<void> _restorePreviousSession({bool fromResume = false}) async {
    if (_isRestoringSession) return;
    if (!fromResume && _hasAttemptedStartupRestore) return;
    if (state.pendingGameId != null) return;
    if (state.status is SetupSuccess ||
        state.status is SetupProfileSelection ||
        state.status is SetupLoading) {
      return;
    }

    if (!fromResume) {
      _hasAttemptedStartupRestore = true;
    }

    final gameCode = _prefs.getString(_prefSessionGameCode)?.trim();
    final playerName = _prefs.getString(_prefSessionPlayerName)?.trim();
    final avatarId = _prefs.getString(_prefSessionAvatarId)?.trim() ?? '';

    if (gameCode == null ||
        gameCode.isEmpty ||
        playerName == null ||
        playerName.isEmpty) {
      return;
    }

    _isRestoringSession = true;
    emit(
      state.copyWith(
        isRestoringSession: true,
        playerName: playerName,
        avatarId: avatarId,
      ),
    );

    try {
      final response = await _repository.joinGame(
        gameId: gameCode,
        playerName: playerName,
        avatarId: avatarId,
      );
      await _persistActiveSession(response.game, response.playerId);
      emit(
        state.copyWith(
          status: SetupSuccess(response.game, response.playerId),
          clearPendingGameId: true,
          isRestoringSession: false,
        ),
      );
    } catch (_) {
      await _clearActiveSession();
      emit(
        state.copyWith(
          status: const SetupError('session_restore_failed'),
          isRestoringSession: false,
          clearPendingGameId: true,
        ),
      );
    } finally {
      _isRestoringSession = false;
    }
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
      final prefs = _prefs;

      // Load saved preferences
      final savedName = prefs.getString(_prefPlayerName) ?? '';
      final savedJunior = prefs.getBool(_prefJuniorMode) ?? false;
      final savedImpostorCount = prefs.getInt(_prefImpostorCount) ?? 1;
      final savedCategoryIds =
          prefs.getStringList(_prefSelectedCategoryIds) ?? ['animals'];

      // Filter category IDs that might no longer exist
      final validCategoryIds = savedCategoryIds
          .where((id) => categories.any((c) => c.id == id))
          .toList();

      emit(
        state.copyWith(
          categories: categories,
          playerName: savedName,
          avatarId: '', // Always start with no avatar selected
          juniorMode: savedJunior,
          impostorCount: savedImpostorCount.clamp(1, 6),
          selectedCategoryIds: validCategoryIds.isEmpty && categories.isNotEmpty
              ? [categories.first.id]
              : validCategoryIds,
        ),
      );
      await _restorePreviousSession();
    } catch (e) {
      emit(state.copyWith(status: const SetupError('fetch_categories_failed')));
    }
  }

  void updateName(String name) {
    emit(state.copyWith(playerName: name));
    _prefs.setString(_prefPlayerName, name);
  }

  void updateAvatar(String avatarId) {
    final newId = state.avatarId == avatarId ? '' : avatarId;
    emit(state.copyWith(avatarId: newId));
    _prefs.setString(_prefAvatarId, newId);
  }

  void updateIsCreating(bool value) {
    emit(
      state.copyWith(
        isCreating: value,
        pendingGameId: value
            ? null
            : state.pendingGameId, // Clear if starting creation
        occupiedAvatarIds: value ? [] : state.occupiedAvatarIds,
      ),
    );
  }

  void proceedToProfileSelection() {
    emit(state.copyWith(status: const SetupProfileSelection()));
  }

  void backToSettings() async {
    await _clearActiveSession();
    emit(
      state.copyWith(
        status: const SetupInitial(),
        clearPendingGameId: true,
        occupiedAvatarIds: [],
        avatarId: '',
        isCreating: true,
      ),
    );
  }

  void updateGame(Game game) {
    final currentStatus = state.status;
    if (currentStatus is SetupSuccess) {
      _persistActiveSession(game, currentStatus.playerId);
      emit(state.copyWith(status: SetupSuccess(game, currentStatus.playerId)));
    }
  }

  void backToProfile() async {
    // This allows going back from Lobby to Profile Selection
    await _clearActiveSession();
    emit(state.copyWith(status: const SetupProfileSelection()));
  }

  void toggleCategory(String categoryId) {
    final ids = List<String>.from(state.selectedCategoryIds);
    if (ids.contains(categoryId)) {
      if (ids.length > 1) {
        // Prevent zero categories selected
        ids.remove(categoryId);
      }
    } else {
      ids.add(categoryId);
    }
    emit(state.copyWith(selectedCategoryIds: ids));
    _prefs.setStringList(_prefSelectedCategoryIds, ids);
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
          final firstValid = state.categories.firstWhere(
            (c) => c.isJuniorAvailable,
          );
          selectedIds = [firstValid.id];
        } catch (_) {}
      }
    }

    emit(state.copyWith(juniorMode: value, selectedCategoryIds: selectedIds));
    _prefs.setBool(_prefJuniorMode, value);
    _prefs.setStringList(_prefSelectedCategoryIds, selectedIds);
  }

  void toggleSurvival(bool value) {
    emit(state.copyWith(survivalMode: value));
  }

  void setImpostorCount(int count) {
    final normalizedCount = count.clamp(1, 6);
    emit(state.copyWith(impostorCount: normalizedCount));
    _prefs.setInt(_prefImpostorCount, normalizedCount);
  }

  void toggleQuestions(bool value) {
    emit(state.copyWith(questionsMode: value));
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
        language: AppLocalizationUtils.currentDeviceLanguageCode(),
        impostorCount: state.impostorCount,
        juniorMode: state.juniorMode,
        survivalMode: state.survivalMode,
        questionsMode: state.questionsMode,
        timerEnabled: state.timerEnabled,
        timerSeconds: state.timerSeconds,
      );
      emit(
        state.copyWith(
          status: SetupSuccess(response.game, response.playerId),
          clearPendingGameId: true,
        ),
      );
      await _persistActiveSession(response.game, response.playerId);
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
      emit(
        state.copyWith(
          status: SetupSuccess(response.game, response.playerId),
          clearPendingGameId: true,
        ),
      );
      await _persistActiveSession(response.game, response.playerId);
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
      emit(
        state.copyWith(
          status: SetupSuccess(response.game, response.playerId),
          clearPendingGameId: true,
        ),
      );
      await _persistActiveSession(response.game, response.playerId);
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

      emit(
        state.copyWith(
          pendingGameId: cleanCode,
          isCreating: false,
          occupiedAvatarIds: occupiedIds,
          avatarId: nextAvatar,
          status: const SetupProfileSelection(),
        ),
      );
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

  Future<void> restorePreviousSessionOnResume() async {
    await _restorePreviousSession(fromResume: true);
  }
}
