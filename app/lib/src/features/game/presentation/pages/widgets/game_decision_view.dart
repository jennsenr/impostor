import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/player.dart';
import '../../../../../shared/presentation/localization/app_localizations.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';
import 'game_progress_widgets.dart';

class GameDecisionView extends StatelessWidget {
  final bool isAlive;
  final bool hasDecided;
  final bool isProcessingDecision;
  final int alivePlayers;
  final int decidedPlayers;
  final List<Player> alivePlayersList;
  final VoidCallback onGoToVoting;
  final VoidCallback onAnotherRound;

  const GameDecisionView({
    super.key,
    required this.isAlive,
    required this.hasDecided,
    required this.isProcessingDecision,
    required this.alivePlayers,
    required this.decidedPlayers,
    required this.alivePlayersList,
    required this.onGoToVoting,
    required this.onAnotherRound,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              context.l10n.decisionTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.decisionSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),
            GameActionProgressPanel(
              title: context.l10n.teamDecisions,
              subtitle: context.l10n.teamDecisionsSubtitle,
              progressLabel: context.l10n.decisions,
              players: alivePlayersList,
              isCompleted: (player) => player.hasDecided,
              accent: AppTheme.neonCyan,
            ),
            const SizedBox(height: 48),
            if (isAlive && !hasDecided) ...[
              if (isProcessingDecision)
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
                        color: AppTheme.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onGoToVoting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      context.l10n.goToVote,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onAnotherRound,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: AppTheme.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.l10n.anotherRound,
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
                    ? context.l10n.playersDeciding
                    : context.l10n.waitingForOthers(
                        decidedPlayers,
                        alivePlayers,
                      ),
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
}
