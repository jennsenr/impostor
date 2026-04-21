import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/player.dart';
import '../../../../../shared/presentation/localization/app_localizations.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';
import 'game_progress_widgets.dart';

class GameVotingView extends StatelessWidget {
  final List<Player> alivePlayers;
  final bool meIsAlive;
  final bool meHasVoted;
  final String myPlayerId;
  final ValueChanged<String> onVote;

  const GameVotingView({
    super.key,
    required this.alivePlayers,
    required this.meIsAlive,
    required this.meHasVoted,
    required this.myPlayerId,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    if (!meIsAlive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                context.l10n.youAreOut,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.waitFinalResult,
                style: TextStyle(color: Colors.white38),
              ),
              const SizedBox(height: 28),
              GameActionProgressPanel(
                title: context.l10n.votesRegistered,
                subtitle: context.l10n.votesProgressEliminated,
                progressLabel: context.l10n.votes,
                players: alivePlayers,
                isCompleted: (player) => player.hasVoted,
                accent: AppTheme.occupiedRed,
              ),
            ],
          ),
        ),
      );
    }

    if (meHasVoted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryPurple),
              const SizedBox(height: 24),
              Text(
                context.l10n.voteRegistered,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.waitingRest,
                style: TextStyle(color: Colors.white38),
              ),
              const SizedBox(height: 28),
              GameActionProgressPanel(
                title: context.l10n.votesRegistered,
                subtitle: context.l10n.votesProgressWaiting,
                progressLabel: context.l10n.votes,
                players: alivePlayers,
                isCompleted: (player) => player.hasVoted,
                accent: AppTheme.primaryPurple,
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 92),
              child: Column(
                children: [
                  Text(
                    context.l10n.voteTheImpostor,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.occupiedRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.voteWarning,
                      style: TextStyle(
                        color: AppTheme.occupiedRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GameActionProgressPanel(
              title: context.l10n.votesRegistered,
              subtitle: context.l10n.votesProgressSubtitle,
              progressLabel: context.l10n.votes,
              players: alivePlayers,
              isCompleted: (player) => player.hasVoted,
              accent: AppTheme.occupiedRed,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: alivePlayers.where((p) => p.id != myPlayerId).length,
                itemBuilder: (context, index) {
                  final target = alivePlayers
                      .where((p) => p.id != myPlayerId)
                      .toList()[index];

                  return GestureDetector(
                    onTap: () => onVote(target.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/avatars/avatar_${target.avatarId}.png',
                                fit: BoxFit.cover,
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
}
