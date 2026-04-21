import 'package:json_annotation/json_annotation.dart';
import 'player.dart';
import 'settings.dart';

part 'game.g.dart';

enum GameStatus {
  @JsonValue('WAITING') waiting,
  @JsonValue('AD_PHASE') adPhase,
  @JsonValue('READY') ready,
  @JsonValue('PLAYING') playing,
  @JsonValue('DECISION') decision,
  @JsonValue('VOTING') voting,
  @JsonValue('RESULT') result,
  @JsonValue('FINISHED') finished,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Game {
  final String id;
  final String code;
  final GameStatus status;
  final List<Player> players;
  final Settings settings;
  final int currentRound;
  final int currentTurnIndex;
  final String word;
  @JsonKey(name: 'word_image_url')
  final String? wordImageURL; // Opcional, solo para modo Junior
  final String hostId;
  final bool hostIsPremium;
  final String? winnerTeam;
  final String? expelledId;
  final int starterIndex;
  @JsonKey(name: 'active_category_id')
  final String? activeCategoryId;
  @JsonKey(name: 'active_category_name')
  final String? activeCategoryName;

  Game({
    required this.id,
    required this.code,
    required this.status,
    required this.players,
    required this.settings,
    required this.currentRound,
    required this.currentTurnIndex,
    required this.word,
    this.wordImageURL,
    required this.hostId,
    required this.hostIsPremium,
    this.winnerTeam,
    this.expelledId,
    required this.starterIndex,
    this.activeCategoryId,
    this.activeCategoryName,
  });

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
  Map<String, dynamic> toJson() => _$GameToJson(this);

  Game copyWith({
    String? id,
    String? code,
    GameStatus? status,
    List<Player>? players,
    Settings? settings,
    int? currentRound,
    int? currentTurnIndex,
    String? word,
    String? wordImageURL,
    String? hostId,
    bool? hostIsPremium,
    String? winnerTeam,
    String? expelledId,
    int? starterIndex,
    String? activeCategoryId,
    String? activeCategoryName,
  }) {
    return Game(
      id: id ?? this.id,
      code: code ?? this.code,
      status: status ?? this.status,
      players: players ?? this.players,
      settings: settings ?? this.settings,
      currentRound: currentRound ?? this.currentRound,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      word: word ?? this.word,
      wordImageURL: wordImageURL ?? this.wordImageURL,
      hostId: hostId ?? this.hostId,
      hostIsPremium: hostIsPremium ?? this.hostIsPremium,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      expelledId: expelledId ?? this.expelledId,
      starterIndex: starterIndex ?? this.starterIndex,
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
      activeCategoryName: activeCategoryName ?? this.activeCategoryName,
    );
  }

  // Helper to find myself (based on local playerID)
  Player? getMe(String playerID) {
    try {
      return players.firstWhere((p) => p.id == playerID);
    } catch (_) {
      return null;
    }
  }

  // Helper to check if it's my turn
  bool isMyTurn(String myPlayerID) {
    if (status != GameStatus.playing) return false;
    if (currentTurnIndex < 0 || currentTurnIndex >= players.length) return false;
    return players[currentTurnIndex].id == myPlayerID;
  }

  Player? getCurrentTurnPlayer() {
    if (currentTurnIndex < 0 || currentTurnIndex >= players.length) return null;
    return players[currentTurnIndex];
  }

  Player? getQuestionTarget() {
    if (status != GameStatus.playing || players.isEmpty) return null;
    if (currentTurnIndex < 0 || currentTurnIndex >= players.length) return null;

    for (var step = 1; step < players.length; step++) {
      final nextIndex = (currentTurnIndex + step) % players.length;
      final player = players[nextIndex];
      if (player.isAlive) {
        return player;
      }
    }

    return null;
  }
}
