import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/player.dart';
import '../../../../../shared/presentation/localization/app_localizations.dart';
import '../../../../../shared/presentation/theme/app_theme.dart';

class GameQuestionRelay extends StatelessWidget {
  final Player activePlayer;
  final Player targetPlayer;

  const GameQuestionRelay({
    super.key,
    required this.activePlayer,
    required this.targetPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.06),
            AppTheme.primaryPurple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.08),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            context.l10n.questionAsks(activePlayer.name.toUpperCase()),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            targetPlayer.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GameQuestionParticipantCard(
                  label: context.l10n.questionLabel,
                  player: activePlayer,
                  accent: AppTheme.primaryPurple,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.neonCyan.withValues(alpha: 0.9),
                  size: 28,
                ),
              ),
              Expanded(
                child: GameQuestionParticipantCard(
                  label: context.l10n.answerLabel,
                  player: targetPlayer,
                  accent: AppTheme.neonCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GameQuestionParticipantCard extends StatelessWidget {
  final String label;
  final Player player;
  final Color accent;

  const GameQuestionParticipantCard({
    super.key,
    required this.label,
    required this.player,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/avatars/avatar_${player.avatarId}.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            player.name.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: Colors.white,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}
