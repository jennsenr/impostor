import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:impostor/src/features/game/presentation/cubit/game_cubit.dart';
import 'package:impostor/src/features/game/presentation/cubit/game_state.dart';
import 'package:impostor/src/features/game/presentation/pages/game_page.dart';
import 'package:impostor/src/domain/models/game.dart';
import 'package:impostor/src/domain/models/player.dart';
import 'package:impostor/src/domain/models/settings.dart';

class MockGameCubit extends Mock implements GameCubit {}

void main() {
  late MockGameCubit mockGameCubit;

  final baseGame = Game(
    id: 'g1',
    code: '1234',
    status: GameStatus.adPhase,
    players: [
      Player(id: 'p1', name: 'P1', avatarId: 'a1', isHost: true),
      Player(id: 'p2', name: 'P2', avatarId: 'a2', isHost: false),
    ],
    settings: Settings(categoryIds: ['animals'], juniorMode: false, survivalMode: false),
    currentRound: 1,
    currentTurnIndex: 0,
    word: 'Leon',
    hostId: 'p1',
    hostIsPremium: false,
    starterIndex: 0,
  );

  setUp(() {
    mockGameCubit = MockGameCubit();
    when(() => mockGameCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockGameCubit.isClosed).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<GameCubit>.value(
        value: mockGameCubit,
        child: const GamePage(),
      ),
    );
  }

  group('GamePage Phase UI', () {
    testWidgets('Should show the secret word during Ad Phase', (WidgetTester tester) async {
      when(() => mockGameCubit.state).thenReturn(GameState(
        status: GameLoaded(baseGame.copyWith(status: GameStatus.adPhase)),
        myPlayerId: 'p1',
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Leon'), findsOneWidget);
      expect(find.text('ENTENDIDO'), findsOneWidget);
    });

    testWidgets('Should show voting list during Voting Phase', (WidgetTester tester) async {
      when(() => mockGameCubit.state).thenReturn(GameState(
        status: GameLoaded(baseGame.copyWith(status: GameStatus.voting)),
        myPlayerId: 'p1',
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('¿QUIÉN ES EL IMPOSTOR?'), findsOneWidget);
      // P2 should be in the list as a candidate
      expect(find.text('P2'), findsOneWidget);
    });
  });
}
