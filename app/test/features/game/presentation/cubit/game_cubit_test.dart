import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:impostor/src/features/game/presentation/cubit/game_cubit.dart';
import 'package:impostor/src/features/game/presentation/cubit/game_state.dart';
import 'package:impostor/src/domain/repositories/game_repository.dart';
import 'package:impostor/src/shared/infrastructure/websocket_service.dart';
import 'package:impostor/src/domain/models/game.dart';
import 'package:impostor/src/domain/models/player.dart';
import 'package:impostor/src/domain/models/settings.dart';

class MockGameRepository extends Mock implements GameRepository {}
class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  late GameCubit gameCubit;
  late MockGameRepository mockRepo;
  late MockWebSocketService mockWs;
  late StreamController<Game> gameController;

  final initialGame = Game(
    id: 'g1',
    code: '1234',
    status: GameStatus.adPhase,
    players: [
      Player(id: 'p1', name: 'P1', avatarId: 'a1', isHost: true), 
      Player(id: 'p2', name: 'P2', avatarId: 'a2')
    ],
    settings: Settings(categoryIds: ['animals'], juniorMode: false, survivalMode: false),
    currentRound: 1,
    currentTurnIndex: 0,
    word: 'Lion',
    hostId: 'p1',
    hostIsPremium: false,
    starterIndex: 0,
  );

  setUp(() {
    mockRepo = MockGameRepository();
    mockWs = MockWebSocketService();
    gameController = StreamController<Game>.broadcast();
    
    when(() => mockWs.gameStream).thenAnswer((_) => gameController.stream);
    when(() => mockWs.connect(any(), any())).thenAnswer((_) async {});
    
    gameCubit = GameCubit(mockRepo, mockWs, 'p1');
  });

  tearDown(() {
    gameCubit.close();
    gameController.close();
  });

  group('GameCubit', () {
    test('init emits GameLoaded and connects WS', () {
      gameCubit.init(initialGame);
      expect(gameCubit.state.status, isA<GameLoaded>());
      verify(() => mockWs.connect('g1', 'p1')).called(1);
    });

    blocTest<GameCubit, GameState>(
      'Should handle ready player correctly',
      build: () {
        when(() => mockRepo.readyPlayer(any(), any())).thenAnswer((_) async {});
        return gameCubit;
      },
      act: (cubit) async {
        cubit.init(initialGame.copyWith(status: GameStatus.ready));
        await cubit.ready();
      },
      expect: () => [
        isA<GameState>().having((s) => s.status, 'status', isA<GameLoaded>()),
        isA<GameState>().having((s) => s.isReady, 'isReady', true),
      ],
      verify: (_) {
         verify(() => mockRepo.readyPlayer('g1', 'p1')).called(1);
      },
    );

    blocTest<GameCubit, GameState>(
      'Should handle vote submission correctly',
      build: () {
        when(() => mockRepo.submitVote(
          gameId: any(named: 'gameId'),
          voterId: any(named: 'voterId'),
          targetId: any(named: 'targetId'),
        )).thenAnswer((_) async {});
        return gameCubit;
      },
      act: (cubit) async {
        cubit.init(initialGame.copyWith(status: GameStatus.voting));
        await cubit.vote('p2');
      },
      verify: (_) {
        verify(() => mockRepo.submitVote(
          gameId: 'g1',
          voterId: 'p1',
          targetId: 'p2',
        )).called(1);
      },
    );
    blocTest<GameCubit, GameState>(
      'Should emit GameLeft and disconnect WS on leaveGame',
      build: () {
        when(() => mockRepo.leaveGame(any(), any())).thenAnswer((_) async {});
        return gameCubit;
      },
      act: (cubit) async {
        cubit.init(initialGame);
        await cubit.leaveGame();
      },
      expect: () => [
        isA<GameState>().having((s) => s.status, 'status', isA<GameLoaded>()),
        isA<GameState>().having((s) => s.isLeaving, 'isLeaving', true),
        isA<GameState>().having((s) => s.status, 'status', isA<GameLeft>()),
      ],
      verify: (_) {
         verify(() => mockRepo.leaveGame('g1', 'p1')).called(1);
         verify(() => mockWs.disconnect()).called(1);
      },
    );

    blocTest<GameCubit, GameState>(
      'Should handle fallback GameLeft emission on repository error',
      build: () {
        when(() => mockRepo.leaveGame(any(), any())).thenThrow(Exception('Server error'));
        return gameCubit;
      },
      act: (cubit) async {
        cubit.init(initialGame);
        await cubit.leaveGame();
      },
      expect: () => [
        isA<GameState>().having((s) => s.status, 'status', isA<GameLoaded>()),
        isA<GameState>().having((s) => s.isLeaving, 'isLeaving', true),
        isA<GameState>().having((s) => s.status, 'status', isA<GameLeft>()),
      ],
      verify: (_) {
         verify(() => mockRepo.leaveGame('g1', 'p1')).called(1);
         verify(() => mockWs.disconnect()).called(1);
      },
    );

    test('Should start next round timer automatically on ties (Result)', () {
      fakeAsync((async) {
        when(() => mockRepo.nextRound(any(), any())).thenAnswer((_) async {});
        
        final gameWithResult = initialGame.copyWith(
          status: GameStatus.result,
          winnerTeam: null, // No winner, meaning a tie or continuing
        );

        gameCubit.init(gameWithResult);

        // En un emit local, podemos forzar un evento de actualización simulando llegada
        // Pero init ya verifica el estatus y arranca el timer si es result
        gameController.add(gameWithResult);
        async.flushMicrotasks();

        // Verificar que no se ha llamado aún si no pasaron los 4 segundos
        verifyNever(() => mockRepo.nextRound('g1', 'p1'));

        // Avanzar el tiempo 4 segundos
        async.elapse(const Duration(seconds: 4));

        // Como `p1` es host y no hay ganador, se debió llamar a nextRound automáticamente
        verify(() => mockRepo.nextRound('g1', 'p1')).called(1);
      });
    });
  });
}
