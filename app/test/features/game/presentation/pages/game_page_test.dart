import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:impostor/src/domain/repositories/game_repository.dart';
import 'package:impostor/src/shared/infrastructure/ads_service.dart';
import 'package:impostor/src/shared/infrastructure/websocket_service.dart';
import 'package:impostor/src/shared/presentation/localization/app_localizations.dart';
import 'package:impostor/src/features/game/presentation/cubit/game_cubit.dart';
import 'package:impostor/src/features/game/presentation/cubit/game_state.dart';
import 'package:impostor/src/features/game/presentation/pages/game_page.dart';
import 'package:impostor/src/domain/models/game.dart';
import 'package:impostor/src/domain/models/player.dart';
import 'package:impostor/src/domain/models/settings.dart';
import 'package:impostor/src/domain/models/ws_event.dart';
import 'package:impostor/src/features/setup/presentation/cubit/setup_cubit.dart';
import 'package:impostor/src/features/setup/presentation/cubit/setup_state.dart';
import 'package:impostor/src/shared/infrastructure/service_locator.dart';

class MockGameCubit extends Mock implements GameCubit {}

class MockSetupCubit extends Mock implements SetupCubit {}

class MockGameRepository extends Mock implements GameRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockAdsService extends Mock implements AdsService {}

void main() {
  late MockGameCubit mockGameCubit;
  late MockSetupCubit mockSetupCubit;
  late MockAdsService mockAdsService;

  final baseGame = Game(
    id: 'g1',
    code: '1234',
    status: GameStatus.adPhase,
    players: [
      Player(id: 'p1', name: 'P1', avatarId: '1', isHost: true),
      Player(id: 'p2', name: 'P2', avatarId: '2', isHost: false),
    ],
    settings: Settings(
      categoryIds: ['animals'],
      juniorMode: false,
      survivalMode: false,
    ),
    currentRound: 1,
    currentTurnIndex: 0,
    word: 'Leon',
    hostId: 'p1',
    hostIsPremium: false,
    starterIndex: 0,
  );

  setUpAll(() {
    registerFallbackValue(baseGame);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockGameCubit = MockGameCubit();
    mockSetupCubit = MockSetupCubit();
    mockAdsService = MockAdsService();
    when(() => mockGameCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockGameCubit.isClosed).thenReturn(false);
    when(() => mockGameCubit.finishAd()).thenAnswer((_) async => true);
    when(
      () => mockSetupCubit.state,
    ).thenReturn(const SetupState(status: SetupInitial()));
    when(() => mockSetupCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockSetupCubit.updateGame(any())).thenReturn(null);
    when(() => mockSetupCubit.backToSettings()).thenReturn(null);
    when(() => mockSetupCubit.backToProfile()).thenReturn(null);
    when(() => mockAdsService.preloadInterstitial()).thenAnswer((_) async {});
    when(
      () => mockAdsService.showInterstitialIfReady(
        waitForLoad: const Duration(milliseconds: 800),
      ),
    ).thenAnswer((_) async => true);

    sl.allowReassignment = true;
    sl.registerSingleton<SetupCubit>(mockSetupCubit);
    sl.registerSingleton<AdsService>(mockAdsService);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: ImpostorLocalizations.localizationsDelegates,
      supportedLocales: ImpostorLocalizations.supportedLocales,
      home: BlocProvider<GameCubit>.value(
        value: mockGameCubit,
        child: const GamePage(),
      ),
    );
  }

  group('GamePage Phase UI', () {
    testWidgets('Should show reveal prompt during Ready Phase', (
      WidgetTester tester,
    ) async {
      when(() => mockGameCubit.state).thenReturn(
        GameState(
          status: GameLoaded(baseGame.copyWith(status: GameStatus.ready)),
          myPlayerId: 'p1',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('TOCA PARA REVELAR'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.text('0 / 2 LISTOS'), findsOneWidget);
    });

    testWidgets('Should show voting list during Voting Phase', (
      WidgetTester tester,
    ) async {
      when(() => mockGameCubit.state).thenReturn(
        GameState(
          status: GameLoaded(baseGame.copyWith(status: GameStatus.voting)),
          myPlayerId: 'p1',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('VOTA AL IMPOSTOR'), findsOneWidget);
      expect(find.text('0 / 2 VOTOS'), findsOneWidget);
      // P2 should be in the list as a candidate
      expect(find.text('P2'), findsWidgets);
    });

    testWidgets('Should not render mock ad screen during Ad Phase', (
      WidgetTester tester,
    ) async {
      when(() => mockGameCubit.state).thenReturn(
        GameState(
          status: GameLoaded(baseGame.copyWith(status: GameStatus.adPhase)),
          myPlayerId: 'p1',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('IMPOSTOR PREMIUM'), findsNothing);
      expect(find.text('PREPARANDO PUBLICIDAD...'), findsNothing);
      expect(find.text('MOSTRANDO PUBLICIDAD...'), findsNothing);
    });

    testWidgets('Should return to home flow when game is left', (
      WidgetTester tester,
    ) async {
      final stateController = StreamController<GameState>.broadcast();
      addTearDown(stateController.close);

      when(() => mockGameCubit.state).thenReturn(
        GameState(
          status: GameLoaded(baseGame.copyWith(status: GameStatus.playing)),
          myPlayerId: 'p1',
        ),
      );
      when(
        () => mockGameCubit.stream,
      ).thenAnswer((_) => stateController.stream);

      await tester.pumpWidget(createWidgetUnderTest());

      stateController.add(GameState(status: GameLeft(), myPlayerId: 'p1'));
      await tester.pump();

      verify(() => mockSetupCubit.backToSettings()).called(1);
      verifyNever(() => mockSetupCubit.backToProfile());
    });
  });

  group('GamePage ad flow', () {
    late MockGameRepository mockRepo;
    late MockWebSocketService mockWs;
    GameCubit? realGameCubit;
    late StreamController<WebSocketEvent> eventController;
    late StreamController<WebSocketStatus> statusController;

    setUp(() {
      mockRepo = MockGameRepository();
      mockWs = MockWebSocketService();
      eventController = StreamController<WebSocketEvent>.broadcast();
      statusController = StreamController<WebSocketStatus>.broadcast();

      when(() => mockWs.eventStream).thenAnswer((_) => eventController.stream);
      when(
        () => mockWs.statusStream,
      ).thenAnswer((_) => statusController.stream);
      when(() => mockWs.connect(any(), any())).thenAnswer((_) {});
      when(() => mockWs.disconnect()).thenAnswer((_) {});
      when(() => mockRepo.finishAd(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.getGame(any())).thenAnswer((_) async => baseGame);

      realGameCubit = GameCubit(mockRepo, mockWs, 'p1');
    });

    tearDown(() async {
      await realGameCubit?.close();
      await eventController.close();
      await statusController.close();
    });

    testWidgets('Should show interstitial and finish ad automatically', (
      WidgetTester tester,
    ) async {
      final adCompleter = Completer<bool>();
      when(
        () => mockAdsService.showInterstitialIfReady(
          waitForLoad: const Duration(milliseconds: 800),
        ),
      ).thenAnswer((_) => adCompleter.future);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: ImpostorLocalizations.localizationsDelegates,
          supportedLocales: ImpostorLocalizations.supportedLocales,
          home: BlocProvider<GameCubit>.value(
            value: realGameCubit!,
            child: const GamePage(),
          ),
        ),
      );

      realGameCubit!.init(baseGame.copyWith(status: GameStatus.adPhase));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      verify(
        () => mockAdsService.showInterstitialIfReady(
          waitForLoad: const Duration(milliseconds: 800),
        ),
      ).called(1);
      verifyNever(() => mockRepo.finishAd('g1', 'p1'));

      adCompleter.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      verify(() => mockRepo.finishAd('g1', 'p1')).called(1);
    });

    testWidgets('Should handle ad phase immediately on initial loaded state', (
      WidgetTester tester,
    ) async {
      realGameCubit!.init(baseGame.copyWith(status: GameStatus.adPhase));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: ImpostorLocalizations.localizationsDelegates,
          supportedLocales: ImpostorLocalizations.supportedLocales,
          home: BlocProvider<GameCubit>.value(
            value: realGameCubit!,
            child: const GamePage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      verify(
        () => mockAdsService.showInterstitialIfReady(
          waitForLoad: const Duration(milliseconds: 800),
        ),
      ).called(1);
      verify(() => mockRepo.finishAd('g1', 'p1')).called(1);
    });

    testWidgets('Should retry ad completion if finishAd fails once', (
      WidgetTester tester,
    ) async {
      var finishAdAttempts = 0;
      when(() => mockRepo.finishAd(any(), any())).thenAnswer((_) async {
        finishAdAttempts++;
        if (finishAdAttempts == 1) {
          throw Exception('ad_failed');
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: ImpostorLocalizations.localizationsDelegates,
          supportedLocales: ImpostorLocalizations.supportedLocales,
          home: BlocProvider<GameCubit>.value(
            value: realGameCubit!,
            child: const GamePage(),
          ),
        ),
      );

      realGameCubit!.init(baseGame.copyWith(status: GameStatus.adPhase));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 50));

      verify(
        () => mockAdsService.showInterstitialIfReady(
          waitForLoad: const Duration(milliseconds: 800),
        ),
      ).called(2);
      verify(() => mockRepo.finishAd('g1', 'p1')).called(2);
    });

    testWidgets(
      'Should still finish ad phase if no interstitial is available',
      (WidgetTester tester) async {
        when(
          () => mockAdsService.showInterstitialIfReady(
            waitForLoad: const Duration(milliseconds: 800),
          ),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates:
                ImpostorLocalizations.localizationsDelegates,
            supportedLocales: ImpostorLocalizations.supportedLocales,
            home: BlocProvider<GameCubit>.value(
              value: realGameCubit!,
              child: const GamePage(),
            ),
          ),
        );

        realGameCubit!.init(baseGame.copyWith(status: GameStatus.adPhase));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        verify(
          () => mockAdsService.showInterstitialIfReady(
            waitForLoad: const Duration(milliseconds: 800),
          ),
        ).called(1);
        verify(() => mockRepo.finishAd('g1', 'p1')).called(1);
      },
    );
  });
}
