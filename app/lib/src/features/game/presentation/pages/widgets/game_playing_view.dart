import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/game.dart';
import '../../../../../domain/models/player.dart';
import '../../../../../shared/presentation/localization/app_localizations.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';
import 'game_progress_widgets.dart';
import 'game_question_widgets.dart';

class GamePlayingView extends StatelessWidget {
  final Game game;
  final Player activePlayer;
  final Player? questionTarget;
  final bool isMyTurn;
  final int remainingTurnSeconds;
  final VoidCallback onNextTurn;

  const GamePlayingView({
    super.key,
    required this.game,
    required this.activePlayer,
    required this.questionTarget,
    required this.isMyTurn,
    required this.remainingTurnSeconds,
    required this.onNextTurn,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 64,
              ),
              child: Column(
                children: [
                  GameRoundHeader(game: game),
                  const SizedBox(height: 24),
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0F14),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.neonCyan.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.08),
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
                  if (game.settings.questionsMode && questionTarget != null)
                    GameQuestionRelay(
                      activePlayer: activePlayer,
                      targetPlayer: questionTarget!,
                    )
                  else
                    Column(
                      children: [
                        Text(
                          context.l10n.turnOf,
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
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  if (game.settings.timerEnabled) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: remainingTurnSeconds <= 5
                            ? AppTheme.occupiedRed.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: remainingTurnSeconds <= 5
                              ? AppTheme.occupiedRed
                              : Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: remainingTurnSeconds <= 5
                                ? AppTheme.occupiedRed
                                : Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$remainingTurnSeconds',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: remainingTurnSeconds <= 5
                                  ? AppTheme.occupiedRed
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            's',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: remainingTurnSeconds <= 5
                                  ? AppTheme.occupiedRed
                                  : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children:
                        [
                          ...game.players.sublist(game.starterIndex),
                          ...game.players.sublist(0, game.starterIndex),
                        ].map((player) {
                          final isActive = player.id == activePlayer.id;
                          final isDead = !player.isAlive;

                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.primaryPurple
                                    : Colors.white.withValues(alpha: 0.05),
                                width: isActive ? 2 : 1,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryPurple
                                            .withValues(alpha: 0.3),
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
                                          'assets/images/avatars/avatar_${player.avatarId}.png',
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/avatars/avatar_${player.avatarId}.png',
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
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
                              color: AppTheme.buttonLavender.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: onNextTurn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.black87,
                          ),
                          child: Text(
                            context.l10n.readyShort,
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
        },
      ),
    );
  }
}
