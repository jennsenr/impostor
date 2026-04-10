import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:impostor/src/features/setup/presentation/cubit/setup_cubit.dart';
import 'package:impostor/src/features/setup/presentation/cubit/setup_state.dart';
import 'package:impostor/src/domain/repositories/game_repository.dart';
import 'package:impostor/src/shared/infrastructure/service_locator.dart';
import 'package:impostor/src/shared/infrastructure/deep_link_service.dart';
import 'package:impostor/src/domain/models/game.dart';
import 'package:impostor/src/domain/models/category.dart';
import 'package:impostor/src/domain/models/settings.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockDeepLinkService extends Mock implements DeepLinkService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SetupCubit setupCubit;
  late MockGameRepository mockRepo;
  late MockDeepLinkService mockDeepLink;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockRepo = MockGameRepository();
    mockDeepLink = MockDeepLinkService();
    mockPrefs = MockSharedPreferences();

    when(() => mockDeepLink.codeStream).thenAnswer((_) => const Stream.empty());

    when(
      () => mockPrefs.getString('pref_player_name'),
    ).thenReturn('TestPlayer');
    when(() => mockPrefs.getBool('pref_junior_mode')).thenReturn(false);
    when(
      () => mockPrefs.getStringList('pref_selected_category_ids'),
    ).thenReturn(['animals']);

    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(
      () => mockPrefs.setStringList(any(), any()),
    ).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    sl.allowReassignment = true;
    sl.registerSingleton<SharedPreferences>(mockPrefs);

    when(() => mockRepo.getCategories()).thenAnswer(
      (_) async => [
        Category(id: 'animals', name: 'Animals', isJuniorAvailable: true),
      ],
    );

    // We instantiate lazily inside tests if needed, but standard setUp is fine
    setupCubit = SetupCubit(mockRepo, mockDeepLink);
  });

  tearDown(() {
    setupCubit.close();
    sl.reset();
  });

  group('SetupCubit', () {
    test(
      'init loads categories and properties from SharedPreferences',
      () async {
        await Future.delayed(
          Duration.zero,
        ); // allow async loadCategories to finish
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
          SetupError('name_required'),
        ),
      ],
    );

    blocTest<SetupCubit, SetupState>(
      'joinGame success transitions to SetupSuccess',
      build: () {
        when(
          () => mockRepo.joinGame(
            gameId: any(named: 'gameId'),
            playerName: any(named: 'playerName'),
            avatarId: any(named: 'avatarId'),
          ),
        ).thenAnswer(
          (_) async => JoinResponse(
            game: Game(
              id: 'g1',
              code: '1234',
              status: GameStatus.waiting,
              players: [],
              settings: Settings(
                categoryIds: [],
                juniorMode: false,
                survivalMode: false,
              ),
              word: '',
              hostId: '',
              currentRound: 0,
              currentTurnIndex: 0,
              hostIsPremium: false,
              starterIndex: 0,
            ),
            playerId: 'p1',
          ),
        );
        return setupCubit;
      },
      act: (cubit) async => await cubit.joinGame('1234'),
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
      },
    );
  });
}
