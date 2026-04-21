import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/game.dart';
import '../../../../../domain/models/player.dart';
import '../../../../../domain/utils/category_localizer.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';
import 'game_decorations.dart';
import 'game_result_widgets.dart';

class GameResultView extends StatelessWidget {
  final Game game;
  final Player? me;
  final VoidCallback onRematch;
  final VoidCallback onReturnToLobby;
  final Future<void> Function() onReturnToHome;

  const GameResultView({
    super.key,
    required this.game,
    required this.me,
    required this.onRematch,
    required this.onReturnToLobby,
    required this.onReturnToHome,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = game.status == GameStatus.finished;
    if (!isFinished) {
      return GameVoteResultView(game: game);
    }

    final impostorPlayer = game.players.firstWhere(
      (p) => p.isImpostor,
      orElse: () => game.players.first,
    );
    final civiliansWon = game.winnerTeam == 'civilians';
    final winners = game.players
        .where((p) => civiliansWon ? !p.isImpostor : p.isImpostor)
        .toList();
    final amIImpostor = me?.isImpostor ?? false;
    final isMyTeamWinner =
        (civiliansWon && !amIImpostor) || (!civiliansWon && amIImpostor);
    final titleText = isMyTeamWinner ? '¡VICTORIA!' : '¡DERROTA!';
    final pillText = isMyTeamWinner ? 'MISIÓN CUMPLIDA' : 'MISIÓN FALLIDA';

    String subtitleText = '';
    Color subtitleColor = AppTheme.accentBlue;

    if (civiliansWon) {
      subtitleText = 'TRIPULACIÓN\nSUPERVIVIENTE';
      subtitleColor = AppTheme.accentBlue;
    } else if (amIImpostor) {
      subtitleText = 'INFILTRACIÓN\nEXITOSA';
      subtitleColor = AppTheme.accentBlue;
    } else {
      subtitleText = 'EL IMPOSTOR\nHA GANADO';
      subtitleColor = AppTheme.occupiedRed;
    }

    final categoryName =
        (game.activeCategoryName ??
                CategoryLocalizer.localize(
                  game.activeCategoryId ?? '',
                  languageCode: game.settings.language,
                ))
            .toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.5),
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
              GameWinnerShowcase(winners: winners, civiliansWon: civiliansWon),
              const SizedBox(height: 28),
              GameExpelledSummary(game: game, compact: true),
              const SizedBox(height: 40),
              _buildDataCard(categoryName, impostorPlayer),
              const SizedBox(height: 48),
              Text(
                'La revancha mantiene este grupo y la configuración actual.',
                textAlign: TextAlign.center,
                style: GoogleFonts.heebo(
                  fontSize: 12,
                  color: Colors.white54,
                  height: 1.35,
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
                  onPressed: onRematch,
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
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                    width: 1.4,
                  ),
                ),
                child: OutlinedButton(
                  onPressed: onReturnToLobby,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'VOLVER AL LOBBY',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: onReturnToHome,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'VOLVER AL INICIO',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      fontSize: 12,
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

  Widget _buildDataCard(String categoryName, Player impostorPlayer) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated.withValues(alpha: 0.4),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('RONDAS', '${game.currentRound}'.padLeft(2, '0')),
                  _buildStat(
                    'JUGADORES',
                    '${game.players.length}'.padLeft(2, '0'),
                  ),
                  _buildStat(
                    'IMPOSTOR',
                    impostorPlayer.name.toUpperCase(),
                    valueColor: AppTheme.occupiedRed,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          child: GameBracket(
            color: AppTheme.accentBlue,
            size: 40,
            thickness: 2,
            isTop: true,
            isLeft: true,
          ),
        ),
        const Positioned(
          top: 0,
          right: 0,
          child: GameBracket(
            color: AppTheme.accentBlue,
            size: 40,
            thickness: 2,
            isTop: true,
            isLeft: false,
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          child: GameBracket(
            color: AppTheme.accentBlue,
            size: 40,
            thickness: 2,
            isTop: false,
            isLeft: true,
          ),
        ),
        const Positioned(
          bottom: 0,
          right: 0,
          child: GameBracket(
            color: AppTheme.accentBlue,
            size: 40,
            thickness: 2,
            isTop: false,
            isLeft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        const Text('', style: TextStyle(fontSize: 10)),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class GameVoteResultView extends StatelessWidget {
  final Game game;

  const GameVoteResultView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
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
              GameExpelledSummary(game: game),
              const Spacer(),
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
}
