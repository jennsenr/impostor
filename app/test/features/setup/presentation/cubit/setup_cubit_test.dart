import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impostor/src/domain/models/category.dart';
import 'package:impostor/src/domain/models/game.dart';
import 'package:impostor/src/domain/models/player.dart';
import 'package:impostor/src/domain/models/settings.dart';
import 'package:impostor/src/domain/repositories/game_repository.dart';
import 'package:impostor/src/features/setup/presentation/cubit/setup_cubit.dart';
import 'package:impostor/src/features/setup/presentation/cubit/setup_state.dart';
import 'package:impostor/src/shared/infrastructure/deep_link_service.dart';
import 'package:impostor/src/shared/infrastructure/service_locator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockDeepLinkService extends Mock implements DeepLinkService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SetupCubit setupCubit;
  late MockGameRepository mockRepo;
  late MockDeepLinkService mockDeepLink;
  late MockSharedPreferences mockPrefs;
  late Map<String, String> stringPrefs;
  late Map<String, bool> boolPrefs;
  late Map<String, int> intPrefs;
  late Map<String, List<String>> stringListPrefs;

  Game buildGame({
    String code = '1234',
    GameStatus status = GameStatus.waiting,
  }) {
    return Game(
      id: 'g1',
      code: code,
      status: status,
      players: [
        Player(id: 'p1', name: 'TestPlayer', avatarId: '7', isHost: true),
      ],
      settings: Settings(
        categoryIds: ['animals'],
        juniorMode: false,
        survivalMode: false,
      ),
      word: '',
      hostId: 'p1',
      currentRound: 1,
      currentTurnIndex: 0,
      hostIsPremium: false,
      starterIndex: 0,
    );
  }

  setUp(() {
    mockRepo = MockGameRepository();
    mockDeepLink = MockDeepLinkService();
    mockPrefs = MockSharedPreferences();

    stringPrefs = {'pref_player_name': 'TestPlayer', 'pref_avatar_id': ''};
    boolPrefs = {'pref_junior_mode': false};
    intPrefs = {'pref_impostor_count': 1};
    stringListPrefs = {
      'pref_selected_category_ids': ['animals'],
    };

    when(() => mockDeepLink.codeStream).thenAnswer((_) => const Stream.empty());

    when(() => mockPrefs.getString(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments.first as String;
      return stringPrefs[key];
    });
    when(() => mockPrefs.getBool(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments.first as String;
      return boolPrefs[key];
    });
    when(() => mockPrefs.getInt(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments.first as String;
      return intPrefs[key];
    });
    when(() => mockPrefs.getStringList(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments.first as String;
      return stringListPrefs[key];
    });

    when(() => mockPrefs.setString(any(), any())).thenAnswer((
      invocation,
    ) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as String;
      stringPrefs[key] = value;
      return true;
    });
    when(() => mockPrefs.setStringList(any(), any())).thenAnswer((
      invocation,
    ) async {
      final key = invocation.positionalArguments[0] as String;
      final value = (invocation.positionalArguments[1] as List<Object?>)
          .cast<String>();
      stringListPrefs[key] = value;
      return true;
    });
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as bool;
      boolPrefs[key] = value;
      return true;
    });
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as int;
      intPrefs[key] = value;
      return true;
    });
    when(() => mockPrefs.remove(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      stringPrefs.remove(key);
      boolPrefs.remove(key);
      intPrefs.remove(key);
      stringListPrefs.remove(key);
      return true;
    });

    sl.allowReassignment = true;
    sl.registerSingleton<SharedPreferences>(mockPrefs);

    when(() => mockRepo.getCategories()).thenAnswer(
      (_) async => [
        Category(id: 'animals', name: 'Animals', isJuniorAvailable: true),
      ],
    );

    setupCubit = SetupCubit(mockRepo, mockDeepLink);
  });

  tearDown(() async {
    await setupCubit.close();
    await sl.reset();
  });

  group('SetupCubit', () {
    test(
      'init loads categories and properties from SharedPreferences',
      () async {
        await Future<void>.delayed(Duration.zero);
        expect(setupCubit.state.categories.length, 1);
        expect(setupCubit.state.playerName, 'TestPlayer');
      },
    );

    blocTest<SetupCubit, SetupState>(
      'updateName saves to SharedPreferences',
      build: () => setupCubit,
      act: (cubit) => cubit.updateName('NewName'),
      expect: () => [
        isA<SetupState>().having(
          (state) => state.playerName,
          'playerName',
          'NewName',
        ),
      ],
      verify: (_) {
        verify(
          () => mockPrefs.setString('pref_player_name', 'NewName'),
        ).called(1);
      },
    );

    blocTest<SetupCubit, SetupState>(
      'createGame fails if name is empty',
      build: () => setupCubit,
      act: (cubit) {
        cubit.updateName('');
        cubit.createGame();
      },
      expect: () => [
        isA<SetupState>().having((s) => s.playerName, 'playerName', ''),
        isA<SetupState>().having(
          (s) => s.status,
          'status',
          const SetupError('name_required'),
        ),
      ],
    );

    blocTest<SetupCubit, SetupState>(
      'joinGame success transitions to SetupSuccess and persists active session',
      build: () {
        when(
          () => mockRepo.joinGame(
            gameId: any(named: 'gameId'),
            playerName: any(named: 'playerName'),
            avatarId: any(named: 'avatarId'),
          ),
        ).thenAnswer(
          (_) async => JoinResponse(game: buildGame(), playerId: 'p1'),
        );
        return setupCubit;
      },
      act: (cubit) async => cubit.joinGame('1234'),
      expect: () => [
        isA<SetupState>().having(
          (s) => s.status,
          'status',
          isA<SetupLoading>(),
        ),
        isA<SetupState>().having(
          (s) => s.status,
          'status',
          isA<SetupSuccess>(),
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.joinGame(
            gameId: '1234',
            playerName: 'TestPlayer',
            avatarId: '',
          ),
        ).called(1);
        expect(stringPrefs['pref_session_game_code'], '1234');
        expect(stringPrefs['pref_session_player_id'], 'p1');
        expect(stringPrefs['pref_session_player_name'], 'TestPlayer');
        expect(stringPrefs['pref_session_avatar_id'], '7');
      },
    );

    test(
      'restores previous session automatically on startup when data is valid',
      () async {
        stringPrefs['pref_session_game_code'] = 'ABCD';
        stringPrefs['pref_session_player_id'] = 'p1';
        stringPrefs['pref_session_player_name'] = 'Recovered';
        stringPrefs['pref_session_avatar_id'] = '4';

        when(
          () => mockRepo.joinGame(
            gameId: any(named: 'gameId'),
            playerName: any(named: 'playerName'),
            avatarId: any(named: 'avatarId'),
          ),
        ).thenAnswer(
          (_) async => JoinResponse(
            game: buildGame(code: 'ABCD', status: GameStatus.playing).copyWith(
              players: [
                Player(
                  id: 'p1',
                  name: 'Recovered',
                  avatarId: '4',
                  isHost: true,
                ),
              ],
            ),
            playerId: 'p1',
          ),
        );

        final cubit = SetupCubit(mockRepo, mockDeepLink);
        addTearDown(cubit.close);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(cubit.state.status, isA<SetupSuccess>());
        expect(cubit.state.isRestoringSession, isFalse);
        verify(
          () => mockRepo.joinGame(
            gameId: 'ABCD',
            playerName: 'Recovered',
            avatarId: '4',
          ),
        ).called(1);
      },
    );

    test('clears invalid session when automatic restore fails', () async {
      stringPrefs['pref_session_game_code'] = 'ABCD';
      stringPrefs['pref_session_player_id'] = 'p1';
      stringPrefs['pref_session_player_name'] = 'Recovered';
      stringPrefs['pref_session_avatar_id'] = '4';

      when(
        () => mockRepo.joinGame(
          gameId: any(named: 'gameId'),
          playerName: any(named: 'playerName'),
          avatarId: any(named: 'avatarId'),
        ),
      ).thenThrow(Exception('game_not_found'));

      final cubit = SetupCubit(mockRepo, mockDeepLink);
      addTearDown(cubit.close);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.status, const SetupError('session_restore_failed'));
      expect(stringPrefs.containsKey('pref_session_game_code'), isFalse);
      expect(stringPrefs.containsKey('pref_session_player_name'), isFalse);
      verify(() => mockPrefs.remove('pref_session_game_code')).called(1);
    });
  });
}
