import 'dart:ui';

import 'package:flutter/widgets.dart';

export 'package:impostor/l10n/generated/app_localizations.dart'
    show ImpostorLocalizations;

import 'package:impostor/l10n/generated/app_localizations.dart';

class AppLocalizationUtils {
  static String normalizeLanguageCode(String? raw) {
    final languageCode = (raw ?? '').toLowerCase();
    if (languageCode.startsWith('en')) {
      return 'en';
    }
    return 'es';
  }

  static String currentDeviceLanguageCode() {
    return normalizeLanguageCode(
      PlatformDispatcher.instance.locale.languageCode,
    );
  }
}

extension AppLocalizationsX on BuildContext {
  ImpostorLocalizations get l10n => ImpostorLocalizations.of(this)!;
}

extension ImpostorLocalizationsHelpers on ImpostorLocalizations {
  String get languageCode =>
      AppLocalizationUtils.normalizeLanguageCode(localeName);

  String setupError(String code) {
    switch (code) {
      case 'fetch_categories_failed':
        return errorFetchCategories;
      case 'name_required':
        return errorNameRequired;
      case 'category_required':
        return errorCategoryRequired;
      case 'name_already_taken':
        return errorNameTaken;
      case 'avatar_already_taken':
        return errorAvatarTaken;
      case 'game_not_found':
      case 'join_game_failed':
        return errorJoinGame;
      case 'create_game_failed':
        return errorCreateGame;
      case 'minimum_players_required':
        return errorMinimumPlayers;
      case 'session_restore_failed':
        return errorSessionRestore;
      default:
        return errorGeneric;
    }
  }

  String lobbyError(String code) {
    switch (code) {
      case 'start_game_failed':
        return lobbyErrorStartGame;
      case 'update_settings_failed':
        return lobbyErrorUpdateSettings;
      case 'ad_failed':
        return lobbyErrorAd;
      case 'leave_game_failed':
        return lobbyErrorLeave;
      case 'game_deleted':
        return lobbyErrorDeleted;
      case 'not_host':
        return errorNotHost;
      case 'invalid_game_status':
        return errorInvalidGameStatus;
      case 'minimum_players_required':
        return errorMinimumPlayers;
      default:
        return lobbyErrorGeneric;
    }
  }

  String gameError(String code) {
    switch (code) {
      case 'ready_failed':
        return gameErrorReady;
      case 'next_turn_failed':
        return gameErrorNextTurn;
      case 'vote_failed':
        return gameErrorVote;
      case 'decision_failed':
        return gameErrorDecision;
      case 'ad_failed':
        return gameErrorAd;
      case 'rematch_failed':
        return gameErrorRematch;
      case 'next_round_failed':
        return gameErrorNextRound;
      case 'not_host':
        return errorNotHost;
      case 'invalid_game_status':
        return errorInvalidGameStatus;
      default:
        return gameErrorGeneric;
    }
  }

  String roomCodeShareMessage(String code) {
    return shareRoomCodeMessage(code.toUpperCase());
  }

  String roomJoinChannel(String code) {
    return roomJoinChannelLabel(code.toUpperCase());
  }
}
