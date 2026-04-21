// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ImpostorLocalizationsEn extends ImpostorLocalizations {
  ImpostorLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Impostor Game';

  @override
  String get privacyAndConsent => 'PRIVACY AND CONSENT';

  @override
  String get restoringRoom => 'RESTORING ROOM...';

  @override
  String get restoringRoomSubtitle => 'Trying to restore your previous match.';

  @override
  String get errorFetchCategories => 'Categories could not be loaded.';

  @override
  String get errorNameRequired => 'Enter your name before continuing.';

  @override
  String get errorCategoryRequired => 'Select at least one category.';

  @override
  String get errorNameTaken => 'That name is already being used in the room.';

  @override
  String get errorAvatarTaken => 'That avatar is already taken.';

  @override
  String get errorJoinGame => 'The room could not be found. Check the code.';

  @override
  String get errorCreateGame => 'The game could not be created.';

  @override
  String get errorMinimumPlayers =>
      'There are not enough players for that impostor count.';

  @override
  String get errorSessionRestore =>
      'The previous room could not be restored. You can join again manually.';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorNotHost => 'Only the host can do that.';

  @override
  String get errorInvalidGameStatus =>
      'That action is not available right now.';

  @override
  String get homeTitle => 'SET UP\nMATCH';

  @override
  String get homeSubtitle => 'ESTABLISH PROTOCOLS';

  @override
  String get homeCategories => 'CATEGORIES';

  @override
  String get edit => 'EDIT';

  @override
  String get noCategoriesSelected => 'None selected. Tap EDIT.';

  @override
  String get juniorMode => 'JUNIOR MODE';

  @override
  String get juniorModeSubtitle => 'Simplifies terms for younger cadets.';

  @override
  String get survivalMode => 'SURVIVAL MODE';

  @override
  String get survivalModeSubtitle =>
      'The game continues if the expelled player was not the impostor';

  @override
  String get questionsMode => 'QUESTION MODE';

  @override
  String get questionsModeSubtitle => 'Ask questions to discover the impostor';

  @override
  String get timer => 'TIMER';

  @override
  String get timerSubtitle => 'Time limit before losing the turn';

  @override
  String get impostors => 'IMPOSTORS';

  @override
  String get impostorsSubtitle =>
      'Choose how many impostors the match will have.';

  @override
  String get categoriesLoadFailed => 'Categories could not be loaded';

  @override
  String get retry => 'RETRY';

  @override
  String get createGame => 'CREATE MATCH';

  @override
  String get roomCode => 'CODE';

  @override
  String get join => 'JOIN';

  @override
  String get selectCategories => 'SELECT CATEGORIES';

  @override
  String get selectCategoriesSubtitle => 'Choose the worlds to play in.';

  @override
  String get all => 'ALL';

  @override
  String get doneProtocols => 'PROTOCOLS READY';

  @override
  String get nameLabel => 'CREWMATE NAME';

  @override
  String get nameHint => 'ENTER NAME...';

  @override
  String get available => 'AVAILABLE';

  @override
  String get selected => 'SELECTED';

  @override
  String get occupied => 'TAKEN';

  @override
  String get selectAvatarTitle => 'SELECT\nAVATAR';

  @override
  String get selectAvatarSubtitle => 'CHOOSE YOUR CREW AVATAR';

  @override
  String get bindAvatar => 'BIND AVATAR';

  @override
  String get updateAvatar => 'UPDATE AVATAR';

  @override
  String get lobbyInactiveRoom => 'ROOM INACTIVE: THE SERVER CLOSED IT';

  @override
  String get lobbyErrorStartGame => 'The match could not be started.';

  @override
  String get lobbyErrorUpdateSettings => 'The settings could not be saved.';

  @override
  String get lobbyErrorAd => 'The ad could not be confirmed.';

  @override
  String get lobbyErrorLeave => 'The room could not be left.';

  @override
  String get lobbyErrorDeleted => 'The room no longer exists.';

  @override
  String get lobbyErrorGeneric => 'Something went wrong in the lobby.';

  @override
  String get lobbyWaitingRoomLine1 => 'WAITING';

  @override
  String get lobbyWaitingRoomLine2 => 'ROOM';

  @override
  String get room => 'ROOM';

  @override
  String get lobbyCodeLabel => 'CODE:';

  @override
  String get lobbyModesLabel => 'M O D E S :';

  @override
  String get questionsModeBadge => 'QUESTIONS';

  @override
  String get waitingParticipantsLine1 => 'WAITING';

  @override
  String get waitingParticipantsLine2 => 'PARTICIPANTS';

  @override
  String get playersLabel => 'PLAYERS';

  @override
  String get connected => 'CONNECTED';

  @override
  String get disconnected => 'DISCONNECTED';

  @override
  String get host => 'HOST';

  @override
  String get hostOffline => 'HOST (OFF)';

  @override
  String get startGame => 'START MATCH';

  @override
  String minimumPlayersButton(int count) {
    return 'MINIMUM $count PLAYERS';
  }

  @override
  String get waitingForHost => 'WAITING FOR HOST...';

  @override
  String get gameSettings => 'MATCH SETTINGS';

  @override
  String get categories => 'Categories';

  @override
  String get impostorLobbyHint =>
      'To start the room you need at least impostors + 1 players.';

  @override
  String get save => 'SAVE';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get discussionTime => 'DISCUSSION TIME';

  @override
  String get juniorModeTitle => 'Junior Mode';

  @override
  String get survivalModeTitle => 'Survival Mode';

  @override
  String get questionsModeTitle => 'Question Mode';

  @override
  String get timerTitle => 'Timer';

  @override
  String get juniorCategoriesHint => 'Simplified categories for children';

  @override
  String shareLobbyInvite(Object code, Object url) {
    return 'Join my Impostor match.\n\nCode: $code\nLink: $url';
  }

  @override
  String get gameInactiveRoom => 'ROOM INACTIVE: THE SERVER CLOSED IT';

  @override
  String get leaveGameTitle => 'LEAVE MATCH';

  @override
  String get leaveGameBody =>
      'The other players will see that you left the match.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get exit => 'EXIT';

  @override
  String get unknownGameStatus => 'Unknown game status';

  @override
  String get gameErrorReady => 'The player could not be marked as ready';

  @override
  String get gameErrorNextTurn => 'The turn could not advance';

  @override
  String get gameErrorVote => 'The vote could not be sent';

  @override
  String get gameErrorDecision => 'The decision could not be sent';

  @override
  String get gameErrorAd => 'The ad could not be confirmed';

  @override
  String get gameErrorRematch => 'The rematch could not be started';

  @override
  String get gameErrorNextRound => 'The next round could not advance';

  @override
  String get gameErrorGeneric => 'Something went wrong in the match';

  @override
  String playerLeft(Object name) {
    return '$name left the match.';
  }

  @override
  String playerDisconnected(Object name) {
    return '$name disconnected.';
  }

  @override
  String playerReconnected(Object name) {
    return '$name rejoined the match.';
  }

  @override
  String playerJoinedLobby(Object name) {
    return '$name joined the room.';
  }

  @override
  String get round => 'ROUND';

  @override
  String get turnOf => 'TURN OF:';

  @override
  String get readyShort => 'READY';

  @override
  String get decisionTitle => 'DO YOU KNOW WHO IT IS?';

  @override
  String get decisionSubtitle =>
      'Talk it through and decide whether to vote now or play another round.';

  @override
  String get teamDecisions => 'TEAM DECISIONS';

  @override
  String get teamDecisionsSubtitle =>
      'Colored players have already chosen whether to vote now or play another round.';

  @override
  String get decisions => 'DECISIONS';

  @override
  String get goToVote => 'GO TO VOTE';

  @override
  String get anotherRound => 'ANOTHER ROUND';

  @override
  String get playersDeciding => 'The players are deciding...';

  @override
  String waitingForOthers(int done, int total) {
    return 'Waiting for the others ($done/$total)...';
  }

  @override
  String get youAreOut => 'YOU ARE OUT!';

  @override
  String get waitFinalResult => 'Wait for the final result.';

  @override
  String get votesRegistered => 'REGISTERED VOTES';

  @override
  String get votesProgressEliminated =>
      'Follow the vote progress even if you are no longer participating.';

  @override
  String get votes => 'VOTES';

  @override
  String get voteRegistered => 'VOTE REGISTERED';

  @override
  String get waitingRest => 'Waiting for the rest...';

  @override
  String get votesProgressWaiting =>
      'Lit-up players have already cast their vote.';

  @override
  String get voteTheImpostor => 'VOTE THE IMPOSTOR';

  @override
  String get voteWarning => 'If you are wrong, you will pay for it!';

  @override
  String get votesProgressSubtitle => 'Grey avatars have not voted yet.';

  @override
  String questionAsks(Object name) {
    return '$name ASKS';
  }

  @override
  String get questionLabel => 'ASKS';

  @override
  String get answerLabel => 'ANSWERS';

  @override
  String get currentTurnResolutionFailed =>
      'The current turn could not be resolved';

  @override
  String shareRoomCodeMessage(Object code) {
    return 'Join my Impostor room. Code: $code';
  }

  @override
  String roomJoinChannelLabel(Object code) {
    return 'LINK CHANNEL: $code';
  }
}
