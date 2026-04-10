import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../features/setup/presentation/pages/home_page.dart';
import '../../../features/setup/presentation/pages/character_selection_page.dart';
import '../../../domain/models/game.dart';
import '../../../features/lobby/presentation/pages/lobby_page.dart';
import '../../../features/lobby/presentation/cubit/lobby_cubit.dart';
import '../../../features/game/presentation/cubit/game_cubit.dart';
import '../../../features/game/presentation/pages/game_page.dart';
import '../../../features/setup/presentation/cubit/setup_cubit.dart';
import '../../../features/setup/presentation/cubit/setup_state.dart';
import '../../infrastructure/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  static String _lastLocation = '/';

  static int _getDepth(String location) {
    if (location == '/') return 0;
    if (location == '/setup') return 1;
    if (location.startsWith('/lobby')) return 2;
    if (location.startsWith('/game')) return 3;
    return 0;
  }

  static Page<dynamic> _buildPage(Widget child, GoRouterState state) {
    final newLocation = state.matchedLocation;
    final int oldDepth = _getDepth(_lastLocation);
    final int newDepth = _getDepth(newLocation);
    final bool isBack = newDepth < oldDepth;
    
    _lastLocation = newLocation;

    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = isBack ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(sl<SetupCubit>().stream),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPage(const HomePage(), state),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) {
          final cubit = context.read<SetupCubit>();
          return _buildPage(
            BlocProvider.value(
              value: cubit,
              child: const CharacterSelectionPage(),
            ),
            state,
          );
        },
      ),
      GoRoute(
        path: '/lobby',
        pageBuilder: (context, state) {
          final setupState = context.read<SetupCubit>().state;
          if (setupState.status is! SetupSuccess) {
            return _buildPage(const HomePage(), state);
          }

          final success = setupState.status as SetupSuccess;
          return _buildPage(
            BlocProvider(
              create: (context) => LobbyCubit(sl(), sl(), success.playerId)
                ..init(success.game),
              child: const LobbyPage(),
            ),
            state,
          );
        },
      ),
      GoRoute(
        path: '/game',
        pageBuilder: (context, state) {
          final setupState = sl<SetupCubit>().state;
          if (setupState.status is! SetupSuccess) {
            return _buildPage(const HomePage(), state);
          }

          final success = setupState.status as SetupSuccess;
          return _buildPage(
            BlocProvider(
              create: (context) => GameCubit(
                    sl(),
                    sl(),
                    success.playerId,
                  )..init(success.game),
              child: const GamePage(),
            ),
            state,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final setupState = sl<SetupCubit>().state;
      final status = setupState.status;
      final bool isAtHome = state.matchedLocation == '/';
      final bool isAtSetup = state.matchedLocation == '/setup';

      if (status is SetupProfileSelection && !isAtSetup) {
        return '/setup';
      }

      if (status is SetupSuccess) {
        final gameStatus = status.game.status;
        final bool isPlaying = gameStatus != GameStatus.waiting;

        if (isPlaying && state.matchedLocation != '/game') {
          return '/game';
        }

        if (!isPlaying && state.matchedLocation != '/lobby') {
          return '/lobby';
        }
      }

      if (status is SetupInitial && !isAtHome) {
        return '/';
      }

      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
