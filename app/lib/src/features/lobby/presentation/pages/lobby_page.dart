import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../../../domain/models/category.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/models/settings.dart';
import '../../../../domain/models/ws_event.dart';
import '../../../../domain/utils/category_localizer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../shared/config/app_config.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../../../../features/setup/presentation/cubit/setup_cubit.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_state.dart';
import 'package:google_fonts/google_fonts.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LobbyCubit, LobbyState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.transientError != curr.transientError ||
          prev.lastEvent != curr.lastEvent ||
          (prev.status is LobbyLoaded &&
              curr.status is LobbyLoaded &&
              (prev.status as LobbyLoaded).game.status !=
                  (curr.status as LobbyLoaded).game.status),
      listener: (context, state) {
        final status = state.status;
        final lastEvent = state.lastEvent;

        // Mostrar notificaciones de eventos de jugadores
        if (lastEvent != null &&
            lastEvent.type == WebSocketEventType.playerEvent &&
            lastEvent.playerID != state.myPlayerId) {
          _showPlayerEventNotification(context, lastEvent);
        }

        if (status is LobbyLeft) {
          context.read<SetupCubit>().backToProfile();
          return;
        }

        if (status is LobbyError) {
          if (status.message == 'game_deleted') {
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
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
            context.read<SetupCubit>().backToSettings();
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_lobbyErrorMessage(status.message))),
          );
        }

        if (state.transientError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_lobbyErrorMessage(state.transientError!))),
          );
        }

        if (status is LobbyLoaded) {
          // Sincronizar el estado global del juego para la navegación declarativa
          context.read<SetupCubit>().updateGame(status.game);
        }
      },
      builder: (context, state) {
        final status = state.status;
        if (status is LobbyInitial || status is LobbyLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (status is LobbyError) {
          return Scaffold(body: Center(child: Text(status.message)));
        }

        if (status is LobbyLoaded) {
          final game = status.game;

          return Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppTheme.backgroundDark.withOpacity(0.0),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildPixelHeader(
                      context,
                      game.code,
                      state.connectionStatus,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              const SizedBox(height: 24),
                              _buildPixelModesRow(context, game, state),
                              const SizedBox(height: 32),
                              _buildPixelCategoryWall(game),
                              const SizedBox(height: 12),
                              _buildPixelStatusIndicator(game),
                              _buildPixelPlayerGrid(game, state.myPlayerId),
                              const SizedBox(height: 120), // Bottom padding
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: _buildPixelMainButton(
              context,
              game,
              state.myPlayerId,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _lobbyErrorMessage(String code) {
    switch (code) {
      case 'start_game_failed':
        return 'No se pudo iniciar la partida.';
      case 'update_settings_failed':
        return 'No se pudieron guardar los ajustes.';
      case 'ad_failed':
        return 'No se pudo confirmar el anuncio.';
      case 'leave_game_failed':
        return 'No se pudo salir de la sala.';
      case 'game_deleted':
        return 'La sala ya no existe.';
      case 'not_host':
        return 'Solo el host puede hacer esa accion.';
      case 'invalid_game_status':
        return 'Esa accion no esta disponible ahora mismo.';
      default:
        return 'Ha ocurrido un error en la sala.';
    }
  }

  Widget _buildPixelHeader(
    BuildContext context,
    String code,
    WebSocketStatus connectionStatus,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.read<LobbyCubit>().leaveGame(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          Column(
            children: [
              Text(
                'SALA DE',
                style: GoogleFonts.heebo(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.neonCyan,
                  letterSpacing: 2,
                  height: 0.9,
                  shadows: [
                    Shadow(
                      color: AppTheme.neonCyan.withOpacity(0.6),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
              Text(
                'ESPERA',
                style: GoogleFonts.heebo(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.neonCyan,
                  letterSpacing: 2,
                  height: 0.9,
                  shadows: [
                    Shadow(
                      color: AppTheme.neonCyan.withOpacity(0.6),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Builder(
            builder: (cardContext) => InkWell(
              onTap: () => _shareGame(cardContext, code),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.neonCyan.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CODIGO:',
                          style: GoogleFonts.heebo(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          code.toUpperCase(),
                          style: GoogleFonts.heebo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    SvgPicture.asset(
                      'assets/svg/icon_share.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppTheme.neonCyan,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixelModesRow(BuildContext context, Game game, LobbyState state) {
    final isHost = game.hostId == state.myPlayerId;
    final hasActiveModes =
        game.settings.juniorMode ||
        game.settings.survivalMode ||
        game.settings.timerEnabled;

    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          if (hasActiveModes)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'M O D O S :',
                    style: GoogleFonts.heebo(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.neonCyan,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (game.settings.juniorMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SvgPicture.asset(
                        'assets/svg/icon_junior.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          AppTheme.neonCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  if (game.settings.survivalMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SvgPicture.asset(
                        'assets/svg/icon_survival.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          AppTheme.neonCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  if (game.settings.timerEnabled)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/icon_timer.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            AppTheme.neonCyan,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${game.settings.timerSeconds}S',
                          style: GoogleFonts.heebo(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Transform.translate(
              offset: const Offset(
                20,
                0,
              ), // Push even further right to hit the edge
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isHost)
                    IconButton(
                      onPressed: () => _showSettings(
                        context,
                        game,
                        state.availableCategories,
                      ),
                      icon: Icon(
                        Icons.settings,
                        size: 20,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  IconButton(
                    onPressed: () => context.read<LobbyCubit>().leaveGame(),
                    icon: Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixelCategoryWall(Game game) {
    final categories = game.settings.categoryIds;
    if (categories.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: categories.map((catId) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.neonCyan.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Text(
              CategoryLocalizer.localize(catId).toUpperCase(),
              style: GoogleFonts.heebo(
                fontSize: 11,
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPixelStatusIndicator(Game game) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(height: 1, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: AppTheme.neonCyan,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ESPERANDO',
                        style: GoogleFonts.heebo(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.neonCyan,
                          letterSpacing: 3,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'PARTICIPANTES',
                        style: GoogleFonts.heebo(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.neonCyan,
                          letterSpacing: 3,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(height: 1, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${game.players.length} ',
                style: GoogleFonts.heebo(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.neonCyan,
                ),
              ),
              TextSpan(
                text: 'JUGADORES',
                style: GoogleFonts.heebo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPixelPlayerGrid(Game game, String myPlayerId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: game.players.length,
      itemBuilder: (context, index) {
        final player = game.players[index];
        final isHost = player.id == game.hostId;
        final isReady = player.adCompleted;

        final isConnected = player.isConnected;
        
        Color statusColor = Colors.white38;
        String statusLabel = isConnected ? 'CONECTADO' : 'DESCONECTADO';
        Color iconBgColor = isConnected ? AppTheme.neonGreen : Colors.grey;
        Color glowColor = isConnected ? AppTheme.neonGreen : Colors.transparent;
        bool showCheck = isConnected;

        if (isHost) {
          statusColor = AppTheme.neonCyan.withOpacity(0.8);
          statusLabel = isConnected ? 'ANFITRIÓN' : 'ANFITRIÓN (OFF)';
          iconBgColor = AppTheme.neonCyan;
          glowColor = AppTheme.neonCyan;
          showCheck = isConnected;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glowColor.withOpacity(0.35), width: 1.5),
            boxShadow: [
              if (isHost || isReady)
                BoxShadow(
                  color: glowColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: glowColor.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/avatars/avatar_${player.avatarId}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: showCheck
                                ? const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  )
                                : Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white54,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.heebo(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      statusLabel,
                      style: GoogleFonts.heebo(
                        color: statusColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPixelMainButton(
    BuildContext context,
    Game game,
    String myPlayerId,
  ) {
    final isHost = game.hostId == myPlayerId;
    final minPlayers = kDebugMode ? 2 : 3;
    final hasEnoughPlayers = game.players.length >= minPlayers;

    String label = 'ESPERANDO PARTICIPANTES...';
    Color btnColor = Colors.white10;
    VoidCallback? action;

    if (isHost) {
      if (hasEnoughPlayers) {
        label = 'EMPEZAR PARTIDA';
        btnColor = AppTheme.neonCyan;
        action = () => context.read<LobbyCubit>().startGame();
      } else {
        label = 'FALTAN JUGADORES';
        btnColor = Colors.white10;
        action = null;
      }
    } else {
      label = 'ESPERANDO AL ANFITRIÓN...';
      btnColor = Colors.white10;
      action = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (action != null && btnColor != Colors.white10)
              BoxShadow(
                color: btnColor.withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: GoogleFonts.heebo(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: btnColor == Colors.white10 ? Colors.white24 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _shareGame(BuildContext context, String code) {
    // Generar URL robusta evitanto replaceAll que puede fallar con dominios complejos
    final baseUrl = AppConfig.invitationBaseUrl;
    final url = '$baseUrl/$code';

    // Necesario para que funcione en iPads/Tablets
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    Share.share(
      '¡Únete a mi partida de IMPOSTOR! 🕵️‍♂️\n\nCódigo: $code\nEnlace: $url',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  void _showSettings(BuildContext context, Game game, List<Category> availableCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Better for scrollable content
      backgroundColor: AppTheme.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bContext) => _SettingsPanel(
        game: game,
        availableCategories: availableCategories,
        onUpdate: (newSettings) {
          context.read<LobbyCubit>().updateSettings(
            categoryIds: newSettings.categoryIds,
            juniorMode: newSettings.juniorMode,
            survivalMode: newSettings.survivalMode,
            timerEnabled: newSettings.timerEnabled,
            timerSeconds: newSettings.timerSeconds,
          );
        },
      ),
    );
  }
}

class _SettingsPanel extends StatefulWidget {
  final Game game;
  final List<Category> availableCategories;
  final Function(Settings) onUpdate;

  const _SettingsPanel({
    required this.game,
    required this.availableCategories,
    required this.onUpdate,
  });

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  late List<String> _selectedCategories;
  late bool _juniorMode;
  late bool _survivalMode;
  late bool _timerEnabled;
  late int _timerSeconds;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.game.settings.categoryIds);
    _juniorMode = widget.game.settings.juniorMode;
    _survivalMode = widget.game.settings.survivalMode;
    _timerEnabled = widget.game.settings.timerEnabled;
    _timerSeconds = widget.game.settings.timerSeconds;
  }

  void _save() {
    widget.onUpdate(
      widget.game.settings.copyWith(
        categoryIds: _selectedCategories,
        juniorMode: _juniorMode,
        survivalMode: _survivalMode,
        timerEnabled: _timerEnabled,
        timerSeconds: _timerSeconds,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundDark,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AJUSTES DE PARTIDA',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Categorías',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableCategories.map((cat) {
                final isSelected = _selectedCategories.contains(cat.id);
                final isJuniorAllowed = cat.isJuniorAvailable;
                final isDisabled = _juniorMode && !isJuniorAllowed;

                return Opacity(
                  opacity: isDisabled ? 0.4 : 1.0,
                  child: FilterChip(
                    label: Text(
                      cat.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: isDisabled
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(cat.id);
                              } else {
                                if (_selectedCategories.length > 1) {
                                  _selectedCategories.remove(cat.id);
                                }
                              }
                            });
                          },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Modo Junior',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              ),
              subtitle: const Text(
                'Categorías simplificadas para niños',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              value: _juniorMode,
              onChanged: (v) {
                setState(() {
                  _juniorMode = v;
                  if (_juniorMode) {
                    _selectedCategories.retainWhere((id) {
                      final results = widget.availableCategories.where((c) => c.id == id);
                      if (results.isEmpty) return false;
                      return results.first.isJuniorAvailable;
                    });
                    if (_selectedCategories.isEmpty) {
                      final juniorCategories = widget.availableCategories.where(
                        (c) => c.isJuniorAvailable,
                      ).toList();
                      if (juniorCategories.isNotEmpty) {
                        _selectedCategories.add(juniorCategories.first.id);
                      }
                    }
                  }
                });
              },
            ),
            SwitchListTile(
              title: const Text(
                'Modo Supervivencia',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Los jugadores eliminados no pueden votar',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              value: _survivalMode,
              onChanged: (v) => setState(() => _survivalMode = v),
            ),
            SwitchListTile(
              title: const Text(
                'Temporizador',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Tiempo límite para discutir antes de votar',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              value: _timerEnabled,
              onChanged: (v) => setState(() => _timerEnabled = v),
            ),
            if (_timerEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIEMPO DE DISCUSIÓN',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [15, 30, 60].map((sec) {
                        final isSelected = _timerSeconds == sec;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _timerSeconds = sec),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentBlue.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accentBlue
                                      : Colors.white10,
                                ),
                              ),
                              child: Text(
                                '${sec}S',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.accentBlue : Colors.white38,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('GUARDAR CAMBIOS'),
            ),
          ],
        ),
      ),
    ),);
  }
}

void _showPlayerEventNotification(BuildContext context, WebSocketEvent event) {
  String message = '';
  IconData icon = Icons.info_outline;
  Color color = AppTheme.accentBlue;

  switch (event.event) {
    case PlayerEvent.left:
      message = '${event.playerName} ha abandonado la sala.';
      icon = Icons.exit_to_app_rounded;
      color = AppTheme.occupiedRed;
      break;
    case PlayerEvent.disconnected:
      message = '${event.playerName} se ha desconectado.';
      icon = Icons.wifi_off_rounded;
      color = Colors.orange;
      break;
    case PlayerEvent.joined:
      message = '${event.playerName} ha entrado.';
      icon = Icons.person_add_alt_1_rounded;
      color = AppTheme.neonCyan;
      break;
    case PlayerEvent.reconnected:
      message = '${event.playerName} ha vuelto a entrar.';
      icon = Icons.wifi_rounded;
      color = AppTheme.neonPurple;
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
