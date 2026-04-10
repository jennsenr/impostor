import '../../domain/models/category.dart';
import '../../domain/models/game.dart';

class JoinResponse {
  final Game game;
  final String playerId;

  JoinResponse({required this.game, required this.playerId});
}

abstract class GameRepository {
  Future<List<Category>> getCategories();
  
  Future<JoinResponse> createGame({
    required String hostName,
    required String avatarId,
    required List<String> categories,
    required bool juniorMode,
    required bool survivalMode,
    required bool timerEnabled,
    required int timerSeconds,
  });

  Future<JoinResponse> joinGame({
    required String gameId,
    required String playerName,
    required String avatarId,
  });

  Future<Game> getGame(String gameId);
  
  Future<void> startGame(String gameId, String hostId);
  
  Future<void> finishAd(String gameId, String playerId);
  
  Future<void> readyPlayer(String gameId, String playerId);
  
  Future<void> nextTurn(String gameId, String playerId);
  
  Future<void> submitVote({
    required String gameId,
    required String voterId,
    required String targetId,
  });

  Future<void> submitDecision({
    required String gameId,
    required String playerId,
    required bool voteToVoting,
  });

  Future<Map<String, dynamic>> getResults(String gameId);
  
  Future<void> leaveGame(String gameId, String playerId);
  
  Future<void> updateSettings({
    required String gameId,
    required String hostId,
    required List<String> categoryIds,
    required bool juniorMode,
    required bool survivalMode,
    required bool timerEnabled,
    required int timerSeconds,
  });

  Future<void> rematch(String gameId);
  Future<void> nextRound(String gameId, String playerId);
}
