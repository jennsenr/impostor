import 'package:dio/dio.dart';
import '../../domain/models/category.dart';
import '../../domain/models/game.dart';
import '../../domain/repositories/game_repository.dart';
import '../../shared/infrastructure/dio_client.dart';

class ApiGameRepository implements GameRepository {
  final DioClient _client;

  ApiGameRepository(this._client);

  Never _throwParsedDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final rawCode = data['code'] ?? data['error'];
      if (rawCode is String && rawCode.isNotEmpty) {
        throw Exception(rawCode);
      }
    }
    if (error.response?.statusCode == 404) {
      throw Exception('game_not_found');
    }
    throw error;
  }

  @override
  Future<List<Category>> getCategories() async {
    final response = await _client.instance.get('categories');
    return (response.data as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }

  @override
  Future<JoinResponse> createGame({
    required String hostName,
    required String avatarId,
    required List<String> categories,
    required bool juniorMode,
    required bool survivalMode,
    required bool timerEnabled,
    required int timerSeconds,
  }) async {
    try {
      final response = await _client.instance.post('games', data: {
        'host_name': hostName,
        'avatar_id': avatarId,
        'categories': categories,
        'junior_mode': juniorMode,
        'survival_mode': survivalMode,
        'timer_enabled': timerEnabled,
        'timer_seconds': timerSeconds,
      });
    
      // In creation, the backend returns only the game, and we get the HostID from it (it's generated on backend)
      final game = Game.fromJson(response.data);
      _client.setHostID(game.hostId);
    
      // Find my player ID (the host)
      final playerId = game.players.firstWhere((p) => p.id == game.hostId).id;
      _client.setPlayerID(playerId);
    
      return JoinResponse(game: game, playerId: playerId);
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<JoinResponse> joinGame({
    required String gameId,
    required String playerName,
    required String avatarId,
  }) async {
    try {
      final response = await _client.instance.post('games/$gameId/join', data: {
        'player_name': playerName,
        'avatar_id': avatarId,
      });
      
      // Join returns {"player_id": "...", "game": {...}}
      final String playerId = response.data['player_id'];
      final game = Game.fromJson(response.data['game']);
      
      _client.setPlayerID(playerId);
      
      return JoinResponse(game: game, playerId: playerId);
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<Game> getGame(String gameId) async {
    try {
      final response = await _client.instance.get('games/$gameId');
      return Game.fromJson(response.data);
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> startGame(String gameId, String hostId) async {
    try {
      await _client.instance.post('games/$gameId/start', options: Options(
        headers: {'X-Host-ID': hostId}
      ));
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> finishAd(String gameId, String playerId) async {
    try {
      await _client.instance.post(
        'games/$gameId/ad-finished',
        options: Options(headers: {'X-Player-ID': playerId}),
      );
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> readyPlayer(String gameId, String playerId) async {
    try {
      await _client.instance.post('games/$gameId/ready', options: Options(
        headers: {'X-Player-ID': playerId}
      ));
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> nextTurn(String gameId, String playerId) async {
    try {
      await _client.instance.post(
        'games/$gameId/next-turn',
        options: Options(headers: {'X-Player-ID': playerId}),
      );
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> submitVote({
    required String gameId,
    required String voterId,
    required String targetId,
  }) async {
    try {
      await _client.instance.post(
        'games/$gameId/vote',
        data: {
          'target_id': targetId,
        },
        options: Options(headers: {'X-Player-ID': voterId}),
      );
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> submitDecision({
    required String gameId,
    required String playerId,
    required bool voteToVoting,
  }) async {
    try {
      await _client.instance.post(
        'games/$gameId/decision',
        data: {
          'vote_to_voting': voteToVoting,
        },
        options: Options(headers: {'X-Player-ID': playerId}),
      );
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getResults(String gameId) async {
    try {
      final response = await _client.instance.get('games/$gameId/results');
      return response.data;
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> leaveGame(String gameId, String playerId) async {
    try {
      await _client.instance.post('games/$gameId/leave', options: Options(
        headers: {'X-Player-ID': playerId}
      ));
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> updateSettings({
    required String gameId,
    required String hostId,
    required List<String> categoryIds,
    required bool juniorMode,
    required bool survivalMode,
    required bool timerEnabled,
    required int timerSeconds,
  }) async {
    try {
      await _client.instance.put(
        'games/$gameId/settings',
        data: {
          'categories': categoryIds,
          'junior_mode': juniorMode,
          'survival_mode': survivalMode,
          'timer_enabled': timerEnabled,
          'timer_seconds': timerSeconds,
        },
        options: Options(headers: {'X-Host-ID': hostId}),
      );
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> rematch(String gameId) async {
    try {
      await _client.instance.post('games/$gameId/rematch');
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }

  @override
  Future<void> nextRound(String gameId, String playerId) async {
    try {
      await _client.instance.post(
        'games/$gameId/next-round',
        options: Options(headers: {'X-Player-ID': playerId}),
      );
    } on DioException catch (error) {
      _throwParsedDioError(error);
    }
  }
}
