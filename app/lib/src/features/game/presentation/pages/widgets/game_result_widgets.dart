import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/game.dart';
import '../../../../../domain/models/player.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';

class GameWinnerShowcase extends StatelessWidget {
  final List<Player> winners;
  final bool civiliansWon;

  const GameWinnerShowcase({
    super.key,
    required this.winners,
    required this.civiliansWon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = civiliansWon ? AppTheme.accentBlue : AppTheme.occupiedRed;
    final title = civiliansWon ? 'TRIPULANTES GANADORES' : 'IMPOSTOR GANADOR';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            color: accent,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: winners.map((player) {
            return Container(
              width: winners.length == 1 ? 208 : 156,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: accent.withValues(alpha: 0.34),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.18),
                      child: Image.asset(
                        'assets/images/avatars/avatar_${player.avatarId}.png',
                        height: winners.length == 1 ? 188 : 132,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      player.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: winners.length == 1 ? 28 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: winners.length == 1 ? 2.2 : 1.1,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class GameExpelledSummary extends StatelessWidget {
  final Game game;
  final bool compact;

  const GameExpelledSummary({
    super.key,
    required this.game,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final expelledPlayer =
        game.expelledId != null && game.expelledId!.isNotEmpty
        ? game.players.firstWhere(
            (p) => p.id == game.expelledId,
            orElse: () => game.players.first,
          )
        : null;

    final isTie = expelledPlayer == null;
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
              color: AppTheme.surfaceElevated.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(color: Colors.white24, width: 2),
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
              color: AppTheme.primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'HA SIDO EXPULSADO',
              style: GoogleFonts.outfit(
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppTheme.buttonLavender,
              ),
            ),
          ),
        ] else ...[
          Container(
            width: compact ? 84 : 100,
            height: compact ? 84 : 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.3),
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
            'NADIE HA SIDO EXPULSADO',
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
}
