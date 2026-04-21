import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:impostor/src/shared/presentation/localization/app_localizations.dart';
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
      Player(id: 'p1', name: 'Host', avatarId: '1', isHost: true),
      Player(id: 'p2', name: 'Guest', avatarId: '2', isHost: false),
    ],
    settings: Settings(
      categoryIds: ['animals'],
      juniorMode: false,
      survivalMode: false,
    ),
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
      locale: const Locale('es'),
      localizationsDelegates: ImpostorLocalizations.localizationsDelegates,
      supportedLocales: ImpostorLocalizations.supportedLocales,
      home: BlocProvider<LobbyCubit>.value(
        value: mockLobbyCubit,
        child: const LobbyPage(),
      ),
    );
  }

  group('LobbyPage UI', () {
    testWidgets('Should show Start button for host', (
      WidgetTester tester,
    ) async {
      when(
        () => mockLobbyCubit.state,
      ).thenReturn(LobbyState(status: LobbyLoaded(testGame), myPlayerId: 'p1'));

      await tester.pumpWidget(createWidgetUnderTest('p1'));
      await tester.pumpAndSettle();
      expect(find.text('EMPEZAR PARTIDA'), findsOneWidget);
    });

    testWidgets('Should show waiting message for guest', (
      WidgetTester tester,
    ) async {
      when(
        () => mockLobbyCubit.state,
      ).thenReturn(LobbyState(status: LobbyLoaded(testGame), myPlayerId: 'p2'));

      await tester.pumpWidget(createWidgetUnderTest('p2'));
      await tester.pumpAndSettle();
      expect(find.text('ESPERANDO AL ANFITRIÓN...'), findsOneWidget);
    });

    testWidgets('Should show player names correctly', (
      WidgetTester tester,
    ) async {
      when(
        () => mockLobbyCubit.state,
      ).thenReturn(LobbyState(status: LobbyLoaded(testGame), myPlayerId: 'p1'));

      await tester.pumpWidget(createWidgetUnderTest('p1'));
      await tester.pumpAndSettle();
      expect(find.text('HOST'), findsOneWidget);
      expect(find.text('GUEST'), findsOneWidget);
    });
  });
}
