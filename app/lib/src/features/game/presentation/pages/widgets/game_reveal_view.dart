import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/game.dart';
import '../../../../../domain/models/player.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';
import 'game_decorations.dart';
import 'game_progress_widgets.dart';
import 'word_image.dart';

class GameRevealView extends StatelessWidget {
  final Game game;
  final Player? me;
  final bool isReady;
  final bool isRevealed;
  final double revealProgress;
  final String categoryName;
  final String? resolvedWordImageUrl;
  final VoidCallback onToggleReveal;

  const GameRevealView({
    super.key,
    required this.game,
    required this.me,
    required this.isReady,
    required this.isRevealed,
    required this.revealProgress,
    required this.categoryName,
    required this.resolvedWordImageUrl,
    required this.onToggleReveal,
  });

  @override
  Widget build(BuildContext context) {
    final charId = me?.avatarId ?? '1';

    return Stack(
      children: [
        Center(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 140),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 240,
                      width: 240,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
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
                    GestureDetector(
                      onTap: onToggleReveal,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 320),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isRevealed
                                ? AppTheme.neonCyan.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                          boxShadow: isRevealed
                              ? [
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            const Positioned.fill(child: GameCornerBrackets()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
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
                                        child: !isRevealed
                                            ? _buildHiddenState()
                                            : _buildRevealedState(),
                                      ),
                                    ),
                                  ),
                                  _buildFooter(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isRevealed
                          ? 'Si vuelves a tocar, la palabra se ocultará y quedará marcada como revisada.'
                          : 'Toca para revelar. Tras 5 segundos, o al volver a tocar, se ocultará y quedarás listo automáticamente.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.heebo(
                        fontSize: 11,
                        color: Colors.white24,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GameActionProgressPanel(
                      title: 'LISTOS PARA EMPEZAR',
                      subtitle:
                          'El avatar se ilumina cuando cada jugador ya ha revisado su palabra.',
                      progressLabel: 'LISTOS',
                      players: game.players,
                      isCompleted: (player) => player.isReady,
                      accent: AppTheme.primaryPurple,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHiddenState() {
    return Column(
      key: const ValueKey('hidden'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161625),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryPurple.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            size: 52,
            color: AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PALABRA OCULTA',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'TOCA PARA REVELAR',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedState() {
    return Column(
      key: const ValueKey('revealed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (me?.isImpostor == true) ...[
          Text(
            'ERES EL IMPOSTOR',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.occupiedRed,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Despista a los demás tripulantes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
          ),
        ] else ...[
          Text(
            'TU PALABRA:',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 16),
          if (game.settings.juniorMode &&
              resolvedWordImageUrl != null &&
              resolvedWordImageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: WordImage(imageUrl: resolvedWordImageUrl!),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            game.word.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRevealed) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: revealProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.neonCyan,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'SE OCULTARÁ AUTOMÁTICAMENTE',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: AppTheme.neonCyan,
            ),
          ),
        ] else if (isReady) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppTheme.neonGreen.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              'LISTO CONFIRMADO',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: AppTheme.neonGreen,
              ),
            ),
          ),
        ],
        Divider(color: Colors.white.withValues(alpha: 0.05), height: 32),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          ((me?.orderIndex ?? 0) - game.starterIndex) %
                          (game.players.isEmpty ? 1 : game.players.length);
                      if (activeOrder < 0) {
                        activeOrder += game.players.length;
                      }
                      return Text(
                        '${activeOrder + 1}'.padLeft(2, '0'),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
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
                crossAxisAlignment: CrossAxisAlignment.end,
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
                    isRevealed
                        ? (me?.isImpostor == true ? 'IMPOSTOR' : 'TRIPULANTE')
                        : 'DESCONOCIDO',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isRevealed
                          ? (me?.isImpostor == true
                                ? AppTheme.occupiedRed
                                : AppTheme.primaryPurple)
                          : Colors.white.withValues(alpha: 0.2),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
