import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../domain/models/game.dart';
import '../../../../domain/models/player.dart';
import '../../../../domain/models/ws_event.dart';
import '../../../../domain/utils/category_localizer.dart';
import '../../../../shared/config/app_config.dart';
import '../../../../shared/infrastructure/ads_service.dart';
import '../../../../shared/infrastructure/service_locator.dart';
import '../../../../shared/presentation/localization/app_localizations.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../../../setup/presentation/cubit/setup_cubit.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import 'widgets/game_ad_phase_view.dart';
import 'widgets/game_decision_view.dart';
import 'widgets/game_header_widgets.dart';
import 'widgets/game_playing_view.dart';
import 'widgets/game_result_view.dart';
import 'widgets/game_reveal_view.dart';
import 'widgets/game_voting_view.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _isRevealed = false;
  bool _hasImplicitlyReadied = false;
  bool _isProcessingAd = false;
  GameStatus? _lastStatus;
  Timer? _turnTimer;
  Timer? _revealTimer;
  int _remainingTurnSeconds = 0;
  String? _lastTurnKey;
  String? _lastAdPhaseKey;
  double _revealProgress = 0;
  static const int _revealDurationMs = 5000;

  void _manageTimer(Game game, GameState state) {
    if (game.status != GameStatus.playing || !game.settings.timerEnabled) {
      _turnTimer?.cancel();
      _turnTimer = null;
      return;
    }

    final turnKey = '${game.id}_${game.currentRound}_${game.currentTurnIndex}';
    if (_lastTurnKey == turnKey) {
      return;
    }

    _lastTurnKey = turnKey;
    _turnTimer?.cancel();

    setState(() {
      _remainingTurnSeconds = game.settings.timerSeconds;
    });

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTurnSeconds > 0) {
          _remainingTurnSeconds--;
        } else {
          timer.cancel();
          if (game.isMyTurn(state.myPlayerId)) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && game.isMyTurn(state.myPlayerId)) {
                context.read<GameCubit>().nextTurn();
              }
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeHandleAdPhase(Game game, Player? me) async {
    if ((me?.adCompleted ?? true) || _isProcessingAd) {
      return;
    }

    final adPhaseKey = '${game.id}_${game.currentRound}_${game.word}';
    if (_lastAdPhaseKey == adPhaseKey) {
      return;
    }

    setState(() {
      _isProcessingAd = true;
    });

    var didFinishAd = false;
    try {
      await sl<AdsService>().showInterstitialIfReady(
        waitForLoad: const Duration(milliseconds: 800),
      );
      if (!mounted) {
        return;
      }
      didFinishAd = await context.read<GameCubit>().finishAd();
      if (didFinishAd) {
        _lastAdPhaseKey = adPhaseKey;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAd = false;
        });
      }

      if (!didFinishAd && mounted) {
        _lastAdPhaseKey = null;
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) {
            return;
          }
          final currentState = context.read<GameCubit>().state;
          final status = currentState.status;
          if (status is! GameLoaded) {
            return;
          }
          if (status.game.status != GameStatus.adPhase) {
            return;
          }
          _maybeHandleAdPhase(
            status.game,
            status.game.getMe(currentState.myPlayerId),
          );
        });
      }
    }
  }

  void _startRevealCountdown(GameState state, Player? me) {
    _revealTimer?.cancel();
    setState(() {
      _revealProgress = 1;
    });

    const tick = Duration(milliseconds: 100);
    var elapsedMs = 0;

    _revealTimer = Timer.periodic(tick, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      elapsedMs += tick.inMilliseconds;
      final nextProgress = 1 - (elapsedMs / _revealDurationMs);

      if (nextProgress <= 0) {
        timer.cancel();
        _completeRevealFlow(state, me);
        return;
      }

      setState(() {
        _revealProgress = nextProgress;
      });
    });
  }

  void _completeRevealFlow(GameState state, Player? me) {
    final alreadyReady = state.isReady || (me?.isReady ?? false);

    if (!_hasImplicitlyReadied && !alreadyReady) {
      _hasImplicitlyReadied = true;
      context.read<GameCubit>().ready();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRevealed = false;
      _revealProgress = 0;
    });
  }

  void _toggleReveal(GameState state, Player? me) {
    if (_isRevealed) {
      _revealTimer?.cancel();
      _completeRevealFlow(state, me);
      return;
    }

    setState(() {
      _isRevealed = true;
      _revealProgress = 1;
    });
    _startRevealCountdown(state, me);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.lastEvent != curr.lastEvent ||
          prev.transientError != curr.transientError,
      listener: (context, state) {
        final lastEvent = state.lastEvent;

        if (lastEvent != null &&
            lastEvent.type == WebSocketEventType.playerEvent &&
            lastEvent.playerID != state.myPlayerId) {
          _showPlayerEventNotification(context, lastEvent);
        }

        if (state.status is GameDeleted) {
          if (!state.isLeaving) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.gameInactiveRoom,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppTheme.occupiedRed.withValues(alpha: 0.9),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          sl<SetupCubit>().backToSettings();
          return;
        }

        if (state.status is GameLeft) {
          sl<SetupCubit>().backToProfile();
          return;
        }

        if (state.transientError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.gameError(state.transientError!).toUpperCase(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.occupiedRed.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        if (state.status is GameLoaded) {
          final game = (state.status as GameLoaded).game;
          final me = game.getMe(state.myPlayerId);
          sl<SetupCubit>().updateGame(game);
          _manageTimer(game, state);
          if (game.status == GameStatus.finished) {
            sl<AdsService>().preloadInterstitial();
          }

          if (game.status != _lastStatus) {
            if (game.status == GameStatus.ready) {
              _revealTimer?.cancel();
              setState(() {
                _isRevealed = false;
                _hasImplicitlyReadied = false;
                _isProcessingAd = false;
                _revealProgress = 0;
              });
            } else if (game.status == GameStatus.adPhase) {
              setState(() {
                _isProcessingAd = false;
              });
            } else {
              _lastAdPhaseKey = null;
            }
            _lastStatus = game.status;
          }

          if (game.status == GameStatus.adPhase) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _maybeHandleAdPhase(game, me);
              }
            });
          }
        }
      },
      builder: (context, state) {
        final status = state.status;
        if (status is! GameLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final game = status.game;
        final me = game.getMe(state.myPlayerId);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          body: Container(
            constraints: const BoxConstraints.expand(),
            decoration: const BoxDecoration(color: AppTheme.backgroundDark),
            child: Stack(
              children: [
                _buildGameContent(context, state, game, me),
                GameLeaveGameButton(
                  isLeaving: state.isLeaving,
                  onTap: () => _confirmLeaveGame(state),
                ),
                GameRoomCodeBadge(
                  code: game.code,
                  onTap: () => _shareRoomCode(game.code),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveWordImageUrl(String rawUrl) {
    if (rawUrl.startsWith('/')) {
      return '${AppConfig.staticAssetsUrl}$rawUrl';
    }
    return rawUrl;
  }

  Future<void> _shareRoomCode(String code) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    await Share.share(
      context.l10n.roomCodeShareMessage(code),
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> _confirmLeaveGame(GameState state) async {
    if (state.isLeaving) {
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            context.l10n.leaveGameTitle,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          content: Text(
            context.l10n.leaveGameBody,
            style: GoogleFonts.outfit(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                context.l10n.cancel,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: Colors.white60,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.occupiedRed,
                foregroundColor: Colors.white,
              ),
              child: Text(
                context.l10n.exit,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted) {
      await context.read<GameCubit>().leaveGame();
    }
  }

  Widget _buildGameContent(
    BuildContext context,
    GameState state,
    Game game,
    Player? me,
  ) {
    if (game.status == GameStatus.adPhase && (me?.adCompleted ?? false)) {
      return _buildRevealView(state, game, me);
    }

    switch (game.status) {
      case GameStatus.adPhase:
        return const GameAdPhaseView();
      case GameStatus.ready:
        return _buildRevealView(state, game, me);
      case GameStatus.playing:
        return _buildPlayingView(state, game);
      case GameStatus.decision:
        return _buildDecisionView(game, me);
      case GameStatus.voting:
        return _buildVotingView(state, game, me);
      case GameStatus.result:
      case GameStatus.finished:
        return _buildResultView(game, me);
      default:
        return Center(
          child: Text(
            context.l10n.unknownGameStatus,
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildRevealView(GameState state, Game game, Player? me) {
    final isReady = state.isReady || (me?.isReady ?? false);
    final categoryName =
        game.activeCategoryName ??
        CategoryLocalizer.localize(
          game.activeCategoryId ??
              (game.settings.categoryIds.isNotEmpty
                  ? game.settings.categoryIds.first
                  : ''),
          languageCode: game.settings.language,
        );

    return GameRevealView(
      game: game,
      me: me,
      isReady: isReady,
      isRevealed: _isRevealed,
      revealProgress: _revealProgress,
      categoryName: categoryName,
      resolvedWordImageUrl:
          game.wordImageURL == null || game.wordImageURL!.isEmpty
          ? null
          : _resolveWordImageUrl(game.wordImageURL!),
      onToggleReveal: () => _toggleReveal(state, me),
    );
  }

  Widget _buildPlayingView(GameState state, Game game) {
    final activePlayer = game.getCurrentTurnPlayer();
    if (activePlayer == null) {
      return Center(
        child: Text(
          context.l10n.currentTurnResolutionFailed,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GamePlayingView(
      game: game,
      activePlayer: activePlayer,
      questionTarget: game.settings.questionsMode
          ? game.getQuestionTarget()
          : null,
      isMyTurn: game.isMyTurn(state.myPlayerId),
      remainingTurnSeconds: _remainingTurnSeconds,
      onNextTurn: () => context.read<GameCubit>().nextTurn(),
    );
  }

  Widget _buildDecisionView(Game game, Player? me) {
    final alivePlayersList = game.players
        .where((player) => player.isAlive)
        .toList();

    return GameDecisionView(
      isAlive: me?.isAlive ?? false,
      hasDecided: me?.hasDecided ?? false,
      isProcessingDecision: false,
      alivePlayers: alivePlayersList.length,
      decidedPlayers: alivePlayersList
          .where((player) => player.hasDecided)
          .length,
      alivePlayersList: alivePlayersList,
      onGoToVoting: () => context.read<GameCubit>().decide(true),
      onAnotherRound: () => context.read<GameCubit>().decide(false),
    );
  }

  Widget _buildVotingView(GameState state, Game game, Player? me) {
    final alivePlayers = game.players
        .where((player) => player.isAlive)
        .toList();

    return GameVotingView(
      alivePlayers: alivePlayers,
      meIsAlive: me?.isAlive ?? false,
      meHasVoted: me?.hasVoted ?? false,
      myPlayerId: state.myPlayerId,
      onVote: (targetId) => context.read<GameCubit>().vote(targetId),
    );
  }

  Widget _buildResultView(Game game, Player? me) {
    return GameResultView(
      game: game,
      me: me,
      onRematch: () => context.read<GameCubit>().rematch(),
      onReturnToLobby: () {
        sl<SetupCubit>().updateGame(game.copyWith(status: GameStatus.waiting));
      },
      onReturnToHome: () async {
        await context.read<GameCubit>().leaveGame();
        sl<SetupCubit>().backToSettings();
      },
    );
  }

  void _showPlayerEventNotification(
    BuildContext context,
    WebSocketEvent event,
  ) {
    String message = '';
    IconData icon = Icons.info_outline;
    Color color = AppTheme.accentBlue;

    switch (event.event) {
      case PlayerEvent.left:
        message = context.l10n.playerLeft(event.playerName ?? '');
        icon = Icons.exit_to_app_rounded;
        color = AppTheme.occupiedRed;
        break;
      case PlayerEvent.disconnected:
        message = context.l10n.playerDisconnected(event.playerName ?? '');
        icon = Icons.wifi_off_rounded;
        color = Colors.orange;
        break;
      case PlayerEvent.reconnected:
        message = context.l10n.playerReconnected(event.playerName ?? '');
        icon = Icons.wifi_rounded;
        color = Colors.green;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (event.avatarID != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/images/avatars/avatar_${event.avatarID}.png',
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            if (event.avatarID == null) const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
