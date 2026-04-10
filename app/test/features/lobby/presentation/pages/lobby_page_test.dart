import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:impostor/src/features/lobby/presentation/cubit/lobby_cubit.dart';
import 'package:impostor/src/features/lobby/presentation/cubit/lobby_state.dart';
import 'package:impostor/src/features/lobby/presentation/pages/lobby_page.dart';
import 'package:impostor/src/domain/models/game.dart';
import 'package:impostor/src/domain/models/player.dart';
import 'package:impostor/src/domain/models/settings.dart';

class MockLobbyCubit extends Mock implements LobbyCubit {}

void main() {
  late MockLobbyCubit mockLobbyCubit;

  final testGame = Game(
    id: 'g1',
    code: '1234',
    status: GameStatus.waiting,
    players: [
      Player(id: 'p1', name: 'Host', avatarId: 'a1', isHost: true),
      Player(id: 'p2', name: 'Guest', avatarId: 'a2', isHost: false),
    ],
    settings: Settings(categoryIds: ['animals'], juniorMode: false, survivalMode: false),
    currentRound: 1,
    currentTurnIndex: 0,
    word: '',
    hostId: 'p1',
    hostIsPremium: false,
    starterIndex: 0,
  );

  setUp(() {
    mockLobbyCubit = MockLobbyCubit();
    when(() => mockLobbyCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockLobbyCubit.isClosed).thenReturn(false);
  });

  Widget createWidgetUnderTest(String myPlayerId) {
    return MaterialApp(
      home: BlocProvider<LobbyCubit>.value(
        value: mockLobbyCubit,
        child: const LobbyPage(),
      ),
    );
  }

  group('LobbyPage UI', () {
    testWidgets('Should show Start button only for Host', (WidgetTester tester) async {
      // Scenario: I am the host (p1)
      when(() => mockLobbyCubit.state).thenReturn(LobbyState(
        status: LobbyLoaded(testGame),
        myPlayerId: 'p1',
      ));

      await tester.pumpWidget(createWidgetUnderTest('p1'));
      expect(find.text('VER ANUNCIO PARA EMPEZAR'), findsOneWidget);

      // Scenario: I am a guest (p2)
      when(() => mockLobbyCubit.state).thenReturn(LobbyState(
        status: LobbyLoaded(testGame),
        myPlayerId: 'p2',
      ));

      await tester.pumpWidget(createWidgetUnderTest('p2'));
      expect(find.text('VER ANUNCIO PARA EMPEZAR'), findsOneWidget);
    });

    testWidgets('Should show player names correctly', (WidgetTester tester) async {
      when(() => mockLobbyCubit.state).thenReturn(LobbyState(
        status: LobbyLoaded(testGame),
        myPlayerId: 'p1',
      ));

      await tester.pumpWidget(createWidgetUnderTest('p1'));
      expect(find.text('Host'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
    });
  });
}
