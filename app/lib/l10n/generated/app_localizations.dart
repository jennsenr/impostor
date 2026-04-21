import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ImpostorLocalizations
/// returned by `ImpostorLocalizations.of(context)`.
///
/// Applications need to include `ImpostorLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ImpostorLocalizations.localizationsDelegates,
///   supportedLocales: ImpostorLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ImpostorLocalizations.supportedLocales
/// property.
abstract class ImpostorLocalizations {
  ImpostorLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ImpostorLocalizations? of(BuildContext context) {
    return Localizations.of<ImpostorLocalizations>(
      context,
      ImpostorLocalizations,
    );
  }

  static const LocalizationsDelegate<ImpostorLocalizations> delegate =
      _ImpostorLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Impostor Game'**
  String get appTitle;

  /// No description provided for @privacyAndConsent.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY AND CONSENT'**
  String get privacyAndConsent;

  /// No description provided for @restoringRoom.
  ///
  /// In en, this message translates to:
  /// **'RESTORING ROOM...'**
  String get restoringRoom;

  /// No description provided for @restoringRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trying to restore your previous match.'**
  String get restoringRoomSubtitle;

  /// No description provided for @errorFetchCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories could not be loaded.'**
  String get errorFetchCategories;

  /// No description provided for @errorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name before continuing.'**
  String get errorNameRequired;

  /// No description provided for @errorCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one category.'**
  String get errorCategoryRequired;

  /// No description provided for @errorNameTaken.
  ///
  /// In en, this message translates to:
  /// **'That name is already being used in the room.'**
  String get errorNameTaken;

  /// No description provided for @errorAvatarTaken.
  ///
  /// In en, this message translates to:
  /// **'That avatar is already taken.'**
  String get errorAvatarTaken;

  /// No description provided for @errorJoinGame.
  ///
  /// In en, this message translates to:
  /// **'The room could not be found. Check the code.'**
  String get errorJoinGame;

  /// No description provided for @errorCreateGame.
  ///
  /// In en, this message translates to:
  /// **'The game could not be created.'**
  String get errorCreateGame;

  /// No description provided for @errorMinimumPlayers.
  ///
  /// In en, this message translates to:
  /// **'There are not enough players for that impostor count.'**
  String get errorMinimumPlayers;

  /// No description provided for @errorSessionRestore.
  ///
  /// In en, this message translates to:
  /// **'The previous room could not be restored. You can join again manually.'**
  String get errorSessionRestore;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @errorNotHost.
  ///
  /// In en, this message translates to:
  /// **'Only the host can do that.'**
  String get errorNotHost;

  /// No description provided for @errorInvalidGameStatus.
  ///
  /// In en, this message translates to:
  /// **'That action is not available right now.'**
  String get errorInvalidGameStatus;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'SET UP\nMATCH'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ESTABLISH PROTOCOLS'**
  String get homeSubtitle;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get homeCategories;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get edit;

  /// No description provided for @noCategoriesSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected. Tap EDIT.'**
  String get noCategoriesSelected;

  /// No description provided for @juniorMode.
  ///
  /// In en, this message translates to:
  /// **'JUNIOR MODE'**
  String get juniorMode;

  /// No description provided for @juniorModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simplifies terms for younger cadets.'**
  String get juniorModeSubtitle;

  /// No description provided for @survivalMode.
  ///
  /// In en, this message translates to:
  /// **'SURVIVAL MODE'**
  String get survivalMode;

  /// No description provided for @survivalModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The game continues if the expelled player was not the impostor'**
  String get survivalModeSubtitle;

  /// No description provided for @questionsMode.
  ///
  /// In en, this message translates to:
  /// **'QUESTION MODE'**
  String get questionsMode;

  /// No description provided for @questionsModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask questions to discover the impostor'**
  String get questionsModeSubtitle;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'TIMER'**
  String get timer;

  /// No description provided for @timerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time limit before losing the turn'**
  String get timerSubtitle;

  /// No description provided for @impostors.
  ///
  /// In en, this message translates to:
  /// **'IMPOSTORS'**
  String get impostors;

  /// No description provided for @impostorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how many impostors the match will have.'**
  String get impostorsSubtitle;

  /// No description provided for @categoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Categories could not be loaded'**
  String get categoriesLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retry;

  /// No description provided for @createGame.
  ///
  /// In en, this message translates to:
  /// **'CREATE MATCH'**
  String get createGame;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'CODE'**
  String get roomCode;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'JOIN'**
  String get join;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'SELECT CATEGORIES'**
  String get selectCategories;

  /// No description provided for @selectCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the worlds to play in.'**
  String get selectCategoriesSubtitle;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get all;

  /// No description provided for @doneProtocols.
  ///
  /// In en, this message translates to:
  /// **'PROTOCOLS READY'**
  String get doneProtocols;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'CREWMATE NAME'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'ENTER NAME...'**
  String get nameHint;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get available;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get selected;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'TAKEN'**
  String get occupied;

  /// No description provided for @selectAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'SELECT\nAVATAR'**
  String get selectAvatarTitle;

  /// No description provided for @selectAvatarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR CREW AVATAR'**
  String get selectAvatarSubtitle;

  /// No description provided for @bindAvatar.
  ///
  /// In en, this message translates to:
  /// **'BIND AVATAR'**
  String get bindAvatar;

  /// No description provided for @updateAvatar.
  ///
  /// In en, this message translates to:
  /// **'UPDATE AVATAR'**
  String get updateAvatar;

  /// No description provided for @lobbyInactiveRoom.
  ///
  /// In en, this message translates to:
  /// **'ROOM INACTIVE: THE SERVER CLOSED IT'**
  String get lobbyInactiveRoom;

  /// No description provided for @lobbyErrorStartGame.
  ///
  /// In en, this message translates to:
  /// **'The match could not be started.'**
  String get lobbyErrorStartGame;

  /// No description provided for @lobbyErrorUpdateSettings.
  ///
  /// In en, this message translates to:
  /// **'The settings could not be saved.'**
  String get lobbyErrorUpdateSettings;

  /// No description provided for @lobbyErrorAd.
  ///
  /// In en, this message translates to:
  /// **'The ad could not be confirmed.'**
  String get lobbyErrorAd;

  /// No description provided for @lobbyErrorLeave.
  ///
  /// In en, this message translates to:
  /// **'The room could not be left.'**
  String get lobbyErrorLeave;

  /// No description provided for @lobbyErrorDeleted.
  ///
  /// In en, this message translates to:
  /// **'The room no longer exists.'**
  String get lobbyErrorDeleted;

  /// No description provided for @lobbyErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong in the lobby.'**
  String get lobbyErrorGeneric;

  /// No description provided for @lobbyWaitingRoomLine1.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get lobbyWaitingRoomLine1;

  /// No description provided for @lobbyWaitingRoomLine2.
  ///
  /// In en, this message translates to:
  /// **'ROOM'**
  String get lobbyWaitingRoomLine2;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'ROOM'**
  String get room;

  /// No description provided for @lobbyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'CODE:'**
  String get lobbyCodeLabel;

  /// No description provided for @lobbyModesLabel.
  ///
  /// In en, this message translates to:
  /// **'M O D E S :'**
  String get lobbyModesLabel;

  /// No description provided for @questionsModeBadge.
  ///
  /// In en, this message translates to:
  /// **'QUESTIONS'**
  String get questionsModeBadge;

  /// No description provided for @waitingParticipantsLine1.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get waitingParticipantsLine1;

  /// No description provided for @waitingParticipantsLine2.
  ///
  /// In en, this message translates to:
  /// **'PARTICIPANTS'**
  String get waitingParticipantsLine2;

  /// No description provided for @playersLabel.
  ///
  /// In en, this message translates to:
  /// **'PLAYERS'**
  String get playersLabel;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'DISCONNECTED'**
  String get disconnected;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'HOST'**
  String get host;

  /// No description provided for @hostOffline.
  ///
  /// In en, this message translates to:
  /// **'HOST (OFF)'**
  String get hostOffline;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'START MATCH'**
  String get startGame;

  /// No description provided for @minimumPlayersButton.
  ///
  /// In en, this message translates to:
  /// **'MINIMUM {count} PLAYERS'**
  String minimumPlayersButton(int count);

  /// No description provided for @waitingForHost.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR HOST...'**
  String get waitingForHost;

  /// No description provided for @gameSettings.
  ///
  /// In en, this message translates to:
  /// **'MATCH SETTINGS'**
  String get gameSettings;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @impostorLobbyHint.
  ///
  /// In en, this message translates to:
  /// **'To start the room you need at least impostors + 1 players.'**
  String get impostorLobbyHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// No description provided for @discussionTime.
  ///
  /// In en, this message translates to:
  /// **'DISCUSSION TIME'**
  String get discussionTime;

  /// No description provided for @juniorModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Junior Mode'**
  String get juniorModeTitle;

  /// No description provided for @survivalModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Survival Mode'**
  String get survivalModeTitle;

  /// No description provided for @questionsModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Question Mode'**
  String get questionsModeTitle;

  /// No description provided for @timerTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerTitle;

  /// No description provided for @juniorCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Simplified categories for children'**
  String get juniorCategoriesHint;

  /// No description provided for @shareLobbyInvite.
  ///
  /// In en, this message translates to:
  /// **'Join my Impostor match.\n\nCode: {code}\nLink: {url}'**
  String shareLobbyInvite(Object code, Object url);

  /// No description provided for @gameInactiveRoom.
  ///
  /// In en, this message translates to:
  /// **'ROOM INACTIVE: THE SERVER CLOSED IT'**
  String get gameInactiveRoom;

  /// No description provided for @leaveGameTitle.
  ///
  /// In en, this message translates to:
  /// **'LEAVE MATCH'**
  String get leaveGameTitle;

  /// No description provided for @leaveGameBody.
  ///
  /// In en, this message translates to:
  /// **'The other players will see that you left the match.'**
  String get leaveGameBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get exit;

  /// No description provided for @unknownGameStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown game status'**
  String get unknownGameStatus;

  /// No description provided for @gameErrorReady.
  ///
  /// In en, this message translates to:
  /// **'The player could not be marked as ready'**
  String get gameErrorReady;

  /// No description provided for @gameErrorNextTurn.
  ///
  /// In en, this message translates to:
  /// **'The turn could not advance'**
  String get gameErrorNextTurn;

  /// No description provided for @gameErrorVote.
  ///
  /// In en, this message translates to:
  /// **'The vote could not be sent'**
  String get gameErrorVote;

  /// No description provided for @gameErrorDecision.
  ///
  /// In en, this message translates to:
  /// **'The decision could not be sent'**
  String get gameErrorDecision;

  /// No description provided for @gameErrorAd.
  ///
  /// In en, this message translates to:
  /// **'The ad could not be confirmed'**
  String get gameErrorAd;

  /// No description provided for @gameErrorRematch.
  ///
  /// In en, this message translates to:
  /// **'The rematch could not be started'**
  String get gameErrorRematch;

  /// No description provided for @gameErrorNextRound.
  ///
  /// In en, this message translates to:
  /// **'The next round could not advance'**
  String get gameErrorNextRound;

  /// No description provided for @gameErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong in the match'**
  String get gameErrorGeneric;

  /// No description provided for @playerLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left the match.'**
  String playerLeft(Object name);

  /// No description provided for @playerDisconnected.
  ///
  /// In en, this message translates to:
  /// **'{name} disconnected.'**
  String playerDisconnected(Object name);

  /// No description provided for @playerReconnected.
  ///
  /// In en, this message translates to:
  /// **'{name} rejoined the match.'**
  String playerReconnected(Object name);

  /// No description provided for @playerJoinedLobby.
  ///
  /// In en, this message translates to:
  /// **'{name} joined the room.'**
  String playerJoinedLobby(Object name);

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'ROUND'**
  String get round;

  /// No description provided for @turnOf.
  ///
  /// In en, this message translates to:
  /// **'TURN OF:'**
  String get turnOf;

  /// No description provided for @readyShort.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get readyShort;

  /// No description provided for @decisionTitle.
  ///
  /// In en, this message translates to:
  /// **'DO YOU KNOW WHO IT IS?'**
  String get decisionTitle;

  /// No description provided for @decisionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Talk it through and decide whether to vote now or play another round.'**
  String get decisionSubtitle;

  /// No description provided for @teamDecisions.
  ///
  /// In en, this message translates to:
  /// **'TEAM DECISIONS'**
  String get teamDecisions;

  /// No description provided for @teamDecisionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Colored players have already chosen whether to vote now or play another round.'**
  String get teamDecisionsSubtitle;

  /// No description provided for @decisions.
  ///
  /// In en, this message translates to:
  /// **'DECISIONS'**
  String get decisions;

  /// No description provided for @goToVote.
  ///
  /// In en, this message translates to:
  /// **'GO TO VOTE'**
  String get goToVote;

  /// No description provided for @anotherRound.
  ///
  /// In en, this message translates to:
  /// **'ANOTHER ROUND'**
  String get anotherRound;

  /// No description provided for @playersDeciding.
  ///
  /// In en, this message translates to:
  /// **'The players are deciding...'**
  String get playersDeciding;

  /// No description provided for @waitingForOthers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the others ({done}/{total})...'**
  String waitingForOthers(int done, int total);

  /// No description provided for @youAreOut.
  ///
  /// In en, this message translates to:
  /// **'YOU ARE OUT!'**
  String get youAreOut;

  /// No description provided for @waitFinalResult.
  ///
  /// In en, this message translates to:
  /// **'Wait for the final result.'**
  String get waitFinalResult;

  /// No description provided for @votesRegistered.
  ///
  /// In en, this message translates to:
  /// **'REGISTERED VOTES'**
  String get votesRegistered;

  /// No description provided for @votesProgressEliminated.
  ///
  /// In en, this message translates to:
  /// **'Follow the vote progress even if you are no longer participating.'**
  String get votesProgressEliminated;

  /// No description provided for @votes.
  ///
  /// In en, this message translates to:
  /// **'VOTES'**
  String get votes;

  /// No description provided for @voteRegistered.
  ///
  /// In en, this message translates to:
  /// **'VOTE REGISTERED'**
  String get voteRegistered;

  /// No description provided for @waitingRest.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the rest...'**
  String get waitingRest;

  /// No description provided for @votesProgressWaiting.
  ///
  /// In en, this message translates to:
  /// **'Lit-up players have already cast their vote.'**
  String get votesProgressWaiting;

  /// No description provided for @voteTheImpostor.
  ///
  /// In en, this message translates to:
  /// **'VOTE THE IMPOSTOR'**
  String get voteTheImpostor;

  /// No description provided for @voteWarning.
  ///
  /// In en, this message translates to:
  /// **'If you are wrong, you will pay for it!'**
  String get voteWarning;

  /// No description provided for @votesProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grey avatars have not voted yet.'**
  String get votesProgressSubtitle;

  /// No description provided for @questionAsks.
  ///
  /// In en, this message translates to:
  /// **'{name} ASKS'**
  String questionAsks(Object name);

  /// No description provided for @questionLabel.
  ///
  /// In en, this message translates to:
  /// **'ASKS'**
  String get questionLabel;

  /// No description provided for @answerLabel.
  ///
  /// In en, this message translates to:
  /// **'ANSWERS'**
  String get answerLabel;

  /// No description provided for @currentTurnResolutionFailed.
  ///
  /// In en, this message translates to:
  /// **'The current turn could not be resolved'**
  String get currentTurnResolutionFailed;

  /// No description provided for @shareRoomCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Join my Impostor room. Code: {code}'**
  String shareRoomCodeMessage(Object code);

  /// No description provided for @roomJoinChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'LINK CHANNEL: {code}'**
  String roomJoinChannelLabel(Object code);
}

class _ImpostorLocalizationsDelegate
    extends LocalizationsDelegate<ImpostorLocalizations> {
  const _ImpostorLocalizationsDelegate();

  @override
  Future<ImpostorLocalizations> load(Locale locale) {
    return SynchronousFuture<ImpostorLocalizations>(
      lookupImpostorLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_ImpostorLocalizationsDelegate old) => false;
}

ImpostorLocalizations lookupImpostorLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ImpostorLocalizationsEn();
    case 'es':
      return ImpostorLocalizationsEs();
  }

  throw FlutterError(
    'ImpostorLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
