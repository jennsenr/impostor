import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:impostor/src/features/lobby/presentation/cubit/lobby_cubit.dart';
import 'package:impostor/src/features/lobby/presentation/cubit/lobby_state.dart';
import 'package:impostor/src/domain/repositories/game_repository.dart';
import 'package:impostor/src/shared/infrastructure/websocket_service.dart';
import 'package:impostor/src/domain/models/game.dart';
import 'package:impostor/src/domain/models/settings.dart';
import 'package:impostor/src/domain/models/ws_event.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  late LobbyCubit lobbyCubit;
  late MockGameRepository mockRepo;
  late MockWebSocketService mockWs;
  late StreamController<WebSocketEvent> eventController;
  late StreamController<WebSocketStatus> statusController;

  final testGame = Game(
    id: 'g1',
    code: '1234',
    status: GameStatus.waiting,
    players: [],
    settings: Settings(
      categoryIds: ['animals'],
      juniorMode: false,
      survivalMode: false,
    ),
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
    eventController = StreamController<WebSocketEvent>.broadcast();
    statusController = StreamController<WebSocketStatus>.broadcast();

    when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
    when(() => mockWs.eventStream).thenAnswer((_) => eventController.stream);
    when(() => mockWs.statusStream).thenAnswer((_) => statusController.stream);
    when(() => mockWs.connect(any(), any())).thenAnswer((_) {});
    when(() => mockWs.disconnect()).thenAnswer((_) {});

    lobbyCubit = LobbyCubit(mockRepo, mockWs, 'p1');
  });

  tearDown(() {
    lobbyCubit.close();
    eventController.close();
    statusController.close();
  });

  group('LobbyCubit', () {
    test('init connects to WebSocket and emits LobbyLoaded', () async {
      await lobbyCubit.init(testGame);
      expect(lobbyCubit.state.status, isA<LobbyLoaded>());
      verify(() => mockWs.connect('g1', 'p1')).called(1);
    });

    blocTest<LobbyCubit, LobbyState>(
      'Should update game state when receiving update from WebSocket',
      build: () => lobbyCubit,
      act: (cubit) async {
        await cubit.init(testGame);
        eventController.add(
          WebSocketEvent(
            type: WebSocketEventType.gameUpdate,
            game: testGame.copyWith(status: GameStatus.playing),
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<LobbyState>().having(
          (s) => (s.status as LobbyLoaded).game.status,
          'status',
          GameStatus.waiting,
        ),
        isA<LobbyState>().having(
          (s) => (s.status as LobbyLoaded).game.status,
          'status',
          GameStatus.playing,
        ),
      ],
    );

    blocTest<LobbyCubit, LobbyState>(
      'Should call repository.startGame when host starts game',
      build: () {
        when(() => mockRepo.startGame(any(), any())).thenAnswer((_) async {});
        return lobbyCubit;
      },
      act: (cubit) async {
        await cubit.init(testGame);
        await cubit.startGame();
      },
      verify: (_) {
        verify(() => mockRepo.startGame('g1', 'p1')).called(1);
      },
    );

    blocTest<LobbyCubit, LobbyState>(
      'Should call repository.leaveGame and emit LobbyLeft on leaveGame success',
      build: () {
        when(() => mockRepo.leaveGame(any(), any())).thenAnswer((_) async {});
        return lobbyCubit;
      },
      act: (cubit) async {
        await cubit.init(testGame);
        await cubit.leaveGame();
      },
      verify: (_) {
        verify(() => mockRepo.leaveGame('g1', 'p1')).called(1);
      },
      expect: () => [
        isA<LobbyState>().having(
          (state) => state.status,
          'status',
          isA<LobbyLoaded>(),
        ),
        isA<LobbyState>().having((state) => state.isLeaving, 'isLeaving', true),
        isA<LobbyState>().having(
          (state) => state.status,
          'status',
          isA<LobbyLeft>(),
        ),
      ],
    );

    blocTest<LobbyCubit, LobbyState>(
      'Should keep lobby and emit transient error on leaveGame failure',
      build: () {
        when(
          () => mockRepo.leaveGame(any(), any()),
        ).thenThrow(Exception('Backend failed'));
        return lobbyCubit;
      },
      act: (cubit) async {
        await cubit.init(testGame);
        await cubit.leaveGame();
      },
      verify: (_) {
        verify(() => mockRepo.leaveGame('g1', 'p1')).called(1);
      },
      expect: () => [
        isA<LobbyState>().having(
          (state) => state.status,
          'status',
          isA<LobbyLoaded>(),
        ),
        isA<LobbyState>().having((state) => state.isLeaving, 'isLeaving', true),
        isA<LobbyState>()
            .having((state) => state.isLeaving, 'isLeaving', false)
            .having((state) => state.transientError, 'transientError', null),
        isA<LobbyState>()
            .having((state) => state.isLeaving, 'isLeaving', false)
            .having(
              (state) => state.transientError,
              'transientError',
              'Backend failed',
            ),
        isA<LobbyState>().having(
          (state) => state.transientError,
          'transientError',
          null,
        ),
      ],
    );

    blocTest<LobbyCubit, LobbyState>(
      'Should call repository.updateSettings with current settings',
      build: () {
        when(
          () => mockRepo.updateSettings(
            gameId: any(named: 'gameId'),
            hostId: any(named: 'hostId'),
            categoryIds: any(named: 'categoryIds'),
            language: any(named: 'language'),
            impostorCount: any(named: 'impostorCount'),
            juniorMode: any(named: 'juniorMode'),
            survivalMode: any(named: 'survivalMode'),
            questionsMode: any(named: 'questionsMode'),
            timerEnabled: any(named: 'timerEnabled'),
            timerSeconds: any(named: 'timerSeconds'),
          ),
        ).thenAnswer((_) async {});
        return lobbyCubit;
      },
      act: (cubit) async {
        await cubit.init(testGame);
        await cubit.updateSettings();
      },
      verify: (_) {
        verify(
          () => mockRepo.updateSettings(
            gameId: 'g1',
            hostId: 'p1',
            categoryIds: testGame.settings.categoryIds,
            language: any(named: 'language'),
            impostorCount: testGame.settings.impostorCount,
            juniorMode: testGame.settings.juniorMode,
            survivalMode: testGame.settings.survivalMode,
            questionsMode: testGame.settings.questionsMode,
            timerEnabled: testGame.settings.timerEnabled,
            timerSeconds: testGame.settings.timerSeconds,
          ),
        ).called(1);
      },
    );
  });
}
