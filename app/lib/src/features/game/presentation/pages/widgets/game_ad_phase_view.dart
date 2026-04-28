import 'package:flutter/material.dart';

import '../../../../../shared/presentation/theme/app_theme.dart';

class GameAdPhaseView extends StatelessWidget {
  const GameAdPhaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.backgroundDark,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.neonCyan,
        ),
      ),
    );
  }
}
