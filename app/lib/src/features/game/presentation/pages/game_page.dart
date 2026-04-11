import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/models/player.dart';
import '../../../../domain/models/ws_event.dart';
import '../../../../domain/utils/category_localizer.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/config/app_config.dart';
import '../../../../shared/infrastructure/service_locator.dart';
import '../../../setup/presentation/cubit/setup_cubit.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _isRevealed = false;
  bool _hasRevealedOnce = false;
  bool _isProcessingAd = false;
  GameStatus? _lastStatus;
  Timer? _turnTimer;
  int _remainingTurnSeconds = 0;
  String? _lastTurnKey;

  void _manageTimer(Game game, GameState state) {
    if (game.status != GameStatus.playing || !game.settings.timerEnabled) {
      _turnTimer?.cancel();
      _turnTimer = null;
      return;
    }

    final turnKey = '${game.id}_${game.currentRound}_${game.currentTurnIndex}';
    if (_lastTurnKey != turnKey) {
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
              // Wait for 1 second visually showing 0, then auto skip
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
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
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

        // Mostrar notificaciones de eventos de jugadores
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
                  'SALA INACTIVA: EL SERVIDOR LA HA CERRADO',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppTheme.occupiedRed.withOpacity(0.9),
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
                _gameErrorMessage(state.transientError!).toUpperCase(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.occupiedRed.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        if (state.status is GameLoaded) {
          final game = (state.status as GameLoaded).game;
          _manageTimer(game, state);

          // Reset local states when status changes
          if (game.status != _lastStatus) {
            if (game.status == GameStatus.ready) {
              setState(() {
                _isRevealed = false;
                _hasRevealedOnce = false;
                _isProcessingAd = false;
              });
            } else if (game.status == GameStatus.adPhase) {
               setState(() {
                _isProcessingAd = false;
              });
            }
            _lastStatus = game.status;
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
            child: _buildGameContent(context, state, game, me),
          ),
        );
      },
    );
  }

  String _gameErrorMessage(String code) {
    switch (code) {
      case 'ready_failed':
        return 'No se pudo marcar al jugador como listo';
      case 'next_turn_failed':
        return 'No se pudo avanzar el turno';
      case 'vote_failed':
        return 'No se pudo enviar el voto';
      case 'decision_failed':
        return 'No se pudo enviar la decision';
      case 'ad_failed':
        return 'No se pudo confirmar el anuncio';
      case 'rematch_failed':
        return 'No se pudo iniciar la revancha';
      case 'next_round_failed':
        return 'No se pudo avanzar a la siguiente ronda';
      case 'not_host':
        return 'Solo el host puede hacer esa accion';
      case 'invalid_game_status':
        return 'Esa accion no esta disponible en este momento';
      default:
        return 'Ha ocurrido un error en la partida';
    }
  }

  String _resolveWordImageUrl(String rawUrl) {
    if (rawUrl.startsWith('/')) {
      return '${AppConfig.staticAssetsUrl}$rawUrl';
    }
    return rawUrl;
  }

  Widget _buildGameContent(
    BuildContext context,
    GameState state,
    Game game,
    Player? me,
  ) {
    if (game.status == GameStatus.adPhase && (me?.adCompleted ?? false)) {
      return _buildReveal(context, state, game, me);
    }

    switch (game.status) {
      case GameStatus.adPhase:
        return _buildAdPhase(context, game);
      case GameStatus.ready:
        return _buildReveal(context, state, game, me);
      case GameStatus.playing:
        return _buildPlaying(context, state, game, me);
      case GameStatus.decision:
        return _buildDecision(context, state, game, me);
      case GameStatus.voting:
        return _buildVoting(context, state, game, me);
      case GameStatus.result:
      case GameStatus.finished:
        return _buildResult(context, state, game, me);
      default:
        return const Center(child: Text('Estado de juego desconocido'));
    }
  }

  // --- SUB-SCREENS ---

  Widget _buildAdPhase(BuildContext context, Game game) {
    final myPlayerId = context.read<GameCubit>().state.myPlayerId;
    final me = game.getMe(myPlayerId);
    final hasFinished = me?.adCompleted ?? false;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Premium Ad Card ---
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      blurRadius: 15,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mock Ad Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/backgrounds/gaming_ad.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              color: AppTheme.surfaceElevated,
                              child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 48),
                            ),
                          ),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                          if (!hasFinished)
                            const CircularProgressIndicator(
                              color: AppTheme.accentBlue,
                              strokeWidth: 3,
                            ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AD',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'IMPOSTOR PREMIUM',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasFinished
                                ? 'ESPERANDO AL RESTO...'
                                : 'CONTENIDO PATROCINADO',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Player Status List
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: game.players.map((p) {
                              final isReady = p.adCompleted;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isReady
                                            ? AppTheme.neonGreen
                                            : Colors.white.withOpacity(0.05),
                                        width: 2,
                                      ),
                                      boxShadow: isReady
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.neonGreen
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Opacity(
                                      opacity: isReady ? 1.0 : 0.4,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage: AssetImage(
                                          'assets/images/avatars/avatar_${p.avatarId}.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.name.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: isReady
                                          ? AppTheme.neonGreen
                                          : Colors.white24,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),

                          // Skip Button (Visible if not finished)
                          if (!hasFinished)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (_isProcessingAd || hasFinished) ? null : () async {
                                  setState(() => _isProcessingAd = true);
                                  await context.read<GameCubit>().finishAd();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPurple,
                                  disabledBackgroundColor: AppTheme.primaryPurple.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isProcessingAd 
                                  ? const SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : Text(
                                      'SALTAR ANUNCIO',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'La partida comenzará cuando todos estén listos',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReveal(
    BuildContext context,
    GameState state,
    Game game,
    Player? me,
  ) {
    final isReady = state.isReady || (me?.isReady ?? false);
    final categoryName =
        game.activeCategoryName ??
        CategoryLocalizer.localize(
          game.activeCategoryId ??
              (game.settings.categoryIds.isNotEmpty
                  ? game.settings.categoryIds.first
                  : ''),
        );
    final charId = me?.avatarId ?? '1';

    return Stack(
      children: [
        // --- Contenido Principal (Scrollable) ---
        Center(
          child: SafeArea(
            bottom: false, // El botón flotante ya protege el fondo
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  32,
                  24,
                  32,
                  140,
                ), // Padding inferior extra para el botón flotante
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Arte del Personaje ---
                    Container(
                      height: 240,
                      width: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0F14),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.neonCyan.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withOpacity(0.08),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Image.asset(
                                  'assets/images/characters/char_$charId.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Categoría Pill ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CATEGORÍA: ',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryPurple,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            categoryName.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Reveal Card Area (Tap to Toggle) ---
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isRevealed = !_isRevealed;
                          if (_isRevealed) {
                            _hasRevealedOnce = true;
                          }
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 320),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isRevealed
                                ? AppTheme.neonCyan.withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                          boxShadow: _isRevealed
                              ? [
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withOpacity(0.05),
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(child: _CornerBrackets()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Área Central (Estable para evitar saltos)
                                  SizedBox(
                                    height: game.settings.juniorMode
                                        ? 260
                                        : 180,
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: ScaleTransition(
                                                scale: anim,
                                                child: child,
                                              ),
                                            ),
                                        child: !_isRevealed
                                            ? Column(
                                                key: const ValueKey('hidden'),
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Icono de Huella Estilizado
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          20,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF161625,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: AppTheme
                                                            .primaryPurple
                                                            .withOpacity(0.3),
                                                        width: 1.5,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppTheme
                                                              .primaryPurple
                                                              .withOpacity(
                                                                0.15,
                                                              ),
                                                          blurRadius: 20,
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.fingerprint_rounded,
                                                      size: 52,
                                                      color: AppTheme
                                                          .primaryPurple,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Text(
                                                    'PALABRA OCULTA',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'TOCA PARA REVELAR',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 1.5,
                                                      color: AppTheme
                                                          .primaryPurple,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                key: const ValueKey('revealed'),
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Contenido Revelado
                                                  if (me?.isImpostor ==
                                                      true) ...[
                                                    Text(
                                                      'ERES EL IMPOSTOR',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 28,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: AppTheme
                                                            .occupiedRed,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Despista a los demás tripulantes.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12,
                                                        color: Colors.white38,
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    Text(
                                                      'TU PALABRA:',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 2,
                                                        color:
                                                            AppTheme.neonCyan,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    if (game
                                                            .settings
                                                            .juniorMode &&
                                                        game.wordImageURL !=
                                                            null &&
                                                        game
                                                            .wordImageURL!
                                                            .isNotEmpty) ...[
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                        child: Container(
                                                          height: 120,
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.05,
                                                                ),
                                                            border: Border.all(
                                                              color: AppTheme
                                                                  .neonCyan
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                          child: _WordImage(
                                                            imageUrl:
                                                                _resolveWordImageUrl(
                                                                  game.wordImageURL!,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                    ],
                                                    Text(
                                                      game.word.toUpperCase(),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 36,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 4,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),

                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Divider(
                                        color: Colors.white.withOpacity(0.05),
                                        height: 32,
                                      ),

                                      // Fila de Metadatos (Jugador / Rol)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'JUGADOR',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white30,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Builder(
                                                  builder: (context) {
                                                    int activeOrder =
                                                        ((me?.orderIndex ?? 0) -
                                                            game.starterIndex) %
                                                        (game.players.isEmpty
                                                            ? 1
                                                            : game
                                                                  .players
                                                                  .length);
                                                    if (activeOrder < 0)
                                                      activeOrder +=
                                                          game.players.length;
                                                    return Text(
                                                      '${activeOrder + 1}'
                                                          .padLeft(2, '0'),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white,
                                                        letterSpacing: 1,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'ROL',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white30,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _isRevealed
                                                      ? (me?.isImpostor == true
                                                            ? 'IMPOSTOR'
                                                            : 'TRIPULANTE')
                                                      : 'DESCONOCIDO',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    color: _isRevealed
                                                        ? (me?.isImpostor ==
                                                                  true
                                                              ? AppTheme
                                                                    .occupiedRed
                                                              : AppTheme
                                                                    .primaryPurple)
                                                        : Colors.white
                                                              .withOpacity(0.2),
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Asegúrate de que nadie más esté mirando la pantalla antes de revelar tu identidad secreta.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.heebo(
                        fontSize: 11,
                        color: Colors.white24,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // --- Botón Flotante "LISTO" ---
        if (!isReady)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _hasRevealedOnce ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_hasRevealedOnce,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.backgroundDark.withOpacity(0),
                        AppTheme.backgroundDark.withOpacity(0.95),
                        AppTheme.backgroundDark,
                      ],
                      stops: const [0, 0.4, 1],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () => context.read<GameCubit>().ready(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppTheme.primaryPurple.withOpacity(0.5),
                        ),
                        child: Text(
                          'LISTO',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    GameState state,
    Game game,
    Player? me,
  ) {
    final isMyTurn = game.isMyTurn(state.myPlayerId);
    final activePlayer = game.players[game.currentTurnIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            _buildRoundHeader(game),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.neonCyan.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withOpacity(0.08),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/characters/char_${activePlayer.avatarId}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'TURNO DE:',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activePlayer.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
                if (game.settings.timerEnabled) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingTurnSeconds <= 5
                          ? AppTheme.occupiedRed.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _remainingTurnSeconds <= 5
                            ? AppTheme.occupiedRed
                            : Colors.white.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: _remainingTurnSeconds <= 5
                              ? AppTheme.occupiedRed
                              : Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_remainingTurnSeconds',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: _remainingTurnSeconds <= 5
                                ? AppTheme.occupiedRed
                                : Colors.white,
                          ),
                        ),
                        Text(
                          's',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _remainingTurnSeconds <= 5
                                ? AppTheme.occupiedRed
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            // Grid of avatars
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children:
                  [
                    ...game.players.sublist(game.starterIndex),
                    ...game.players.sublist(0, game.starterIndex),
                  ].map((p) {
                    final isActive = p.id == activePlayer.id;
                    final isDead = !p.isAlive;

                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.primaryPurple
                              : Colors.white.withOpacity(0.05),
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Opacity(
                        opacity: isDead ? 0.3 : (isActive ? 1.0 : 0.6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isDead
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  ),
                                  child: Image.asset(
                                    'assets/images/avatars/avatar_${p.avatarId}.png',
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/avatars/avatar_${p.avatarId}.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const Spacer(),
            if (isMyTurn)
              SizedBox(
                height: 64,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.buttonLavender,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.buttonLavender.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.read<GameCubit>().nextTurn(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black87,
                    ),
                    child: Text(
                      'LISTO',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isProcessingDecision = false;

  Widget _buildDecision(
    BuildContext context,
    GameState state,
    Game game,
    Player? me,
  ) {
    final isAlive = me?.isAlive ?? false;
    final hasDecided = me?.hasDecided ?? false;

    final alivePlayers = game.players.where((p) => p.isAlive).length;
    final decidedPlayers = game.players
        .where((p) => p.isAlive && p.hasDecided)
        .length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.help_outline,
              size: 80,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 24),
            const Text(
              '¿SABÉIS YA QUIÉN ES?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hablad y decidid si queréis ir a votación ahora o jugar otra ronda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 48),
            if (isAlive && !hasDecided) ...[
              if (_isProcessingDecision)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.neonCyan),
                )
              else ...[
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withOpacity(0.3),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _isProcessingDecision = true);
                      context.read<GameCubit>().decide(true).then((_) {
                        if (mounted)
                          setState(() => _isProcessingDecision = false);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'IR A VOTACIÓN',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _isProcessingDecision = true);
                    context.read<GameCubit>().decide(false).then((_) {
                      if (mounted)
                        setState(() => _isProcessingDecision = false);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: AppTheme.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'OTRA RONDA',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ] else ...[
              Text(
                !isAlive
                    ? 'Los jugadores están decidiendo...'
                    : 'Esperando a los demás ($decidedPlayers/$alivePlayers)...',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoting(
    BuildContext context,
    GameState state,
    Game game,
    Player? me,
  ) {
    if (me?.isAlive == false) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dangerous_outlined,
              size: 64,
              color: AppTheme.occupiedRed,
            ),
            const SizedBox(height: 24),
            Text(
              '¡ESTÁS FUERA!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Espera al resultado final.',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    if (me?.hasVoted == true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryPurple),
            const SizedBox(height: 24),
            Text(
              'VOTO REGISTRADO',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esperando al resto...',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'VOTA AL IMPOSTOR',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.occupiedRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Si te equivocas, ¡lo pagarás caro!',
                style: TextStyle(
                  color: AppTheme.occupiedRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: game.players
                    .where((p) => p.isAlive && p.id != state.myPlayerId)
                    .length,
                itemBuilder: (context, index) {
                  final target = game.players
                      .where((p) => p.isAlive && p.id != state.myPlayerId)
                      .toList()[index];
                  return GestureDetector(
                    onTap: () => context.read<GameCubit>().vote(target.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/avatars/avatar_${target.avatarId}.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            target.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    GameState state,
    Game game,
    Player? me,
  ) {
    final isFinished = game.status == GameStatus.finished;

    if (!isFinished) {
      return _buildVoteResult(context, game);
    }

    final impostorPlayer = game.players.firstWhere(
      (p) => p.isImpostor,
      orElse: () => game.players.first,
    );
    final civiliansWon = game.winnerTeam == 'civilians';
    final bool amIImpostor = me?.isImpostor ?? false;
    final bool isMyTeamWinner =
        (civiliansWon && !amIImpostor) || (!civiliansWon && amIImpostor);

    final String titleText = isMyTeamWinner ? '¡VICTORIA!' : '¡DERROTA!';
    final String pillText = isMyTeamWinner
        ? 'MISIÓN CUMPLIDA'
        : 'MISIÓN FALLIDA';

    String subtitleText = '';
    Color subtitleColor = AppTheme.accentBlue;

    if (civiliansWon) {
      subtitleText = 'TRIPULACIÓN\nSUPERVIVIENTE';
      subtitleColor = AppTheme.accentBlue;
    } else {
      if (amIImpostor) {
        subtitleText = 'INFILTRACIÓN\nEXITOSA';
        subtitleColor = AppTheme.accentBlue;
      } else {
        subtitleText = 'EL IMPOSTOR\nHA GANADO';
        subtitleColor = AppTheme.occupiedRed;
      }
    }

    // Get active category for the display
    String categoryName =
        (game.activeCategoryName ??
                CategoryLocalizer.localize(game.activeCategoryId ?? ''))
            .toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Gradient Title ---
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.buttonLavender, AppTheme.primaryPurple],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  titleText,
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Pill Status ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  pillText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppTheme.buttonLavender,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- Subtitle ---
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: subtitleColor,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 24),

              _buildExpelledSummary(game, compact: true),

              const SizedBox(height: 24),

              // --- Winning avatars (wrap) ---
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: game.players
                    .where((p) => civiliansWon ? (!p.isImpostor) : p.isImpostor)
                    .map((p) {
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/avatars/avatar_${p.avatarId}.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),

              const SizedBox(height: 40),

              // --- Big Data Card with Neon Brackets ---
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.all(
                      2,
                    ), // margin to not overlap brackets
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated.withOpacity(0.4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'LA CATEGORÍA FUE:',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: AppTheme.buttonLavender,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'LA PALABRA FUE:',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.word.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: AppTheme.buttonLavender,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'RONDAS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${game.currentRound}'.padLeft(2, '0'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'JUGADORES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${game.players.length}'.padLeft(2, '0'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'IMPOSTOR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  impostorPlayer.name.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: AppTheme.occupiedRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildBracket(top: true, left: true),
                  _buildBracket(top: true, left: false),
                  _buildBracket(top: false, left: true),
                  _buildBracket(top: false, left: false),
                ],
              ),

              const SizedBox(height: 48),

              // --- Action Buttons ---
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () => context.read<GameCubit>().rematch(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'REPETIR PARTIDA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<GameCubit>().leaveGame();
                    sl<SetupCubit>().backToSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'VOLVER AL INICIO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBracket({required bool top, required bool left}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: !top ? 0 : null,
      left: left ? 0 : null,
      right: !left ? 0 : null,
      child: Container(
        width: 40,
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: AppTheme.accentBlue, width: 2)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: AppTheme.accentBlue, width: 2)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: AppTheme.accentBlue, width: 2)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: AppTheme.accentBlue, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildVoteResult(BuildContext context, Game game) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildExpelledSummary(game),
              const Spacer(),

              // --- Footer Transition Loader ---
              Column(
                children: [
                  Text(
                    'REINICIANDO ESCENARIO...',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white24,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpelledSummary(Game game, {bool compact = false}) {
    final expelledPlayer =
        game.expelledId != null && game.expelledId!.isNotEmpty
        ? game.players.firstWhere(
            (p) => p.id == game.expelledId,
            orElse: () => game.players.first,
          )
        : null;

    final isTie = expelledPlayer == null;
    final isImpostor = expelledPlayer?.isImpostor == true;

    final avatarSize = compact ? 148.0 : 200.0;
    final cardWidth = compact ? 180.0 : 220.0;
    final titleSize = compact ? 22.0 : 32.0;
    final badgeFontSize = compact ? 11.0 : 14.0;
    final titleSpacing = compact ? 2.0 : 4.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isTie) ...[
          Container(
            width: cardWidth,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withOpacity(0.4),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: (isImpostor ? AppTheme.occupiedRed : Colors.white)
                      .withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: isImpostor ? AppTheme.occupiedRed : Colors.white24,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/avatars/avatar_${expelledPlayer.avatarId}.png',
                        height: avatarSize,
                        fit: BoxFit.contain,
                      ),
                      if (isImpostor)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.occupiedRed.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 20 : 40),
          Text(
            expelledPlayer.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: titleSpacing,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: (isImpostor ? AppTheme.occupiedRed : AppTheme.accentBlue)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color:
                    (isImpostor ? AppTheme.occupiedRed : AppTheme.accentBlue)
                        .withOpacity(0.3),
              ),
            ),
            child: Text(
              isImpostor ? 'ERA EL IMPOSTOR' : 'ERA INOCENTE',
              style: GoogleFonts.outfit(
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color:
                    isImpostor ? AppTheme.occupiedRed : AppTheme.accentBlue,
              ),
            ),
          ),
        ] else ...[
          Container(
            width: compact ? 84 : 100,
            height: compact ? 84 : 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Icon(
                Icons.balance_rounded,
                size: 48,
                color: Colors.white38,
              ),
            ),
          ),
          SizedBox(height: compact ? 20 : 32),
          Text(
            'EMPATE',
            style: GoogleFonts.outfit(
              fontSize: compact ? 28 : 40,
              fontWeight: FontWeight.w900,
              letterSpacing: compact ? 4 : 6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'NADIE HA SIDO ELIMINADO EN ESTA RONDA',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white30,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoundHeader(Game game) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.primaryPurple.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'RONDA ${game.currentRound}',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.primaryPurple.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
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
        message = '${event.playerName} ha abandonado la partida.';
        icon = Icons.exit_to_app_rounded;
        color = AppTheme.occupiedRed;
        break;
      case PlayerEvent.disconnected:
        message = '${event.playerName} se ha desconectado.';
        icon = Icons.wifi_off_rounded;
        color = Colors.orange;
        break;
      case PlayerEvent.reconnected:
        message = '${event.playerName} ha vuelto a entrar.';
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
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  static const Color _color = AppTheme.neonCyan;
  static const double _size = 28;
  static const double _thickness = 2.5;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 0,
          left: 0,
          child: _Bracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: true,
            isLeft: true,
          ),
        ),
        // Top Right
        Positioned(
          top: 0,
          right: 0,
          child: _Bracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: true,
            isLeft: false,
          ),
        ),
        // Bottom Left
        Positioned(
          bottom: 0,
          left: 0,
          child: _Bracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: false,
            isLeft: true,
          ),
        ),
        // Bottom Right
        Positioned(
          bottom: 0,
          right: 0,
          child: _Bracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: false,
            isLeft: false,
          ),
        ),
      ],
    );
  }
}

class _WordImage extends StatefulWidget {
  final String imageUrl;

  const _WordImage({required this.imageUrl});

  @override
  State<_WordImage> createState() => _WordImageState();
}

class _WordImageState extends State<_WordImage> {
  late List<String> _candidates;
  int _candidateIndex = 0;

  @override
  void initState() {
    super.initState();
    _candidates = _buildCandidates(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _WordImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _candidates = _buildCandidates(widget.imageUrl);
      _candidateIndex = 0;
    }
  }

  List<String> _buildCandidates(String url) {
    final candidates = <String>[url];
    final match = RegExp(r'\.([^.\/]+)$').firstMatch(url);
    final hasExtension = match != null;
    final base = hasExtension ? url.substring(0, match.start) : url;

    const extensions = ['png', 'jpg', 'jpeg', 'JPG', 'JPEG', 'PNG'];
    for (final extension in extensions) {
      final candidate = '$base.$extension';
      if (!candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }

    return candidates;
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _candidates[_candidateIndex],
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.neonCyan,
        ),
      ),
      errorWidget: (context, url, error) {
        if (_candidateIndex < _candidates.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _candidateIndex++;
            });
          });
          return const SizedBox.shrink();
        }

        return const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white24,
          size: 48,
        );
      },
    );
  }
}

class _Bracket extends StatelessWidget {
  final Color color;
  final double size;
  final double thickness;
  final bool isTop;
  final bool isLeft;

  const _Bracket({
    required this.color,
    required this.size,
    required this.thickness,
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Horizontal line
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: size, height: thickness, color: color),
          ),
          // Vertical line
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: thickness, height: size, color: color),
          ),
        ],
      ),
    );
  }
}
