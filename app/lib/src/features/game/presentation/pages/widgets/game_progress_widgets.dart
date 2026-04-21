import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/game.dart';
import '../../../../../domain/models/player.dart';
import '../../../../../shared/presentation/localization/app_localizations.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';

class GameActionProgressPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String progressLabel;
  final List<Player> players;
  final bool Function(Player player) isCompleted;
  final Color accent;

  const GameActionProgressPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.players,
    required this.isCompleted,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const SizedBox.shrink();
    }

    final completedCount = players.where(isCompleted).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$completedCount / ${players.length} $progressLabel',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: players.map((player) {
              return GameProgressAvatar(
                player: player,
                completed: isCompleted(player),
                accent: accent,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class GameProgressAvatar extends StatelessWidget {
  final Player player;
  final bool completed;
  final Color accent;

  const GameProgressAvatar({
    super.key,
    required this.player,
    required this.completed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const avatarDiameter = 44.0;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: completed
                    ? accent
                    : Colors.white.withValues(alpha: 0.06),
                width: 2,
              ),
              boxShadow: completed
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.28),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: completed ? 1.0 : 0.32,
              child: ColorFiltered(
                colorFilter: completed
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                child: ClipOval(
                  child: SizedBox(
                    width: avatarDiameter,
                    height: avatarDiameter,
                    child: Image.asset(
                      'assets/images/avatars/avatar_${player.avatarId}.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            player.name.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: completed ? accent : Colors.white24,
              letterSpacing: 0.6,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class GameRoundHeader extends StatelessWidget {
  final Game game;

  const GameRoundHeader({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.primaryPurple.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${context.l10n.round} ${game.currentRound}',
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
                AppTheme.primaryPurple.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
