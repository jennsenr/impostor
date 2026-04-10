import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/infrastructure/service_locator.dart';
import '../../../../shared/infrastructure/websocket_service.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../cubit/setup_cubit.dart';
import '../cubit/setup_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _gameIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Limpiar WebSocket al volver al inicio para evitar canales huérfanos de partidas anteriores
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        sl<WebSocketService>().disconnect();
      }
    });
    // Check if we arrived with a pending game ID from a deep link or similar
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SetupCubit>().state;
      if (state.pendingGameId != null && state.status is SetupInitial) {
        context.read<SetupCubit>().proceedToProfileSelection();
      }
    });
  }

  @override
  void dispose() {
    _gameIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SetupCubit, SetupState>(
        listener: (context, state) {
          if (state.status is SetupError) {
            final error = state.status as SetupError;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_setupErrorMessage(error.message))),
            );
          }
        },
        builder: (context, state) {
          return Container(
            constraints: const BoxConstraints.expand(),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundDark,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    // Main card container for configuration
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildGameOptions(context, state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildActions(context, state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _setupErrorMessage(String code) {
    switch (code) {
      case 'fetch_categories_failed':
        return 'No se pudieron cargar las categorias.';
      case 'name_required':
        return 'Introduce tu nombre antes de continuar.';
      case 'category_required':
        return 'Selecciona al menos una categoria.';
      case 'name_already_taken':
        return 'Ese nombre ya esta en uso en la sala.';
      case 'avatar_already_taken':
        return 'Ese avatar ya esta ocupado.';
      case 'game_not_found':
      case 'join_game_failed':
        return 'No se pudo encontrar la sala. Revisa el codigo.';
      case 'create_game_failed':
        return 'No se pudo crear la partida.';
      default:
        return 'Ha ocurrido un error.';
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'CONFIGURAR\nPARTIDA',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            height: 1.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ESTABLECER PROTOCOLOS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: AppTheme.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOptions(BuildContext context, SetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  'CATEGORÍAS',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showCategorySelectionSheet(context, state),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon( Icons.edit_note_rounded, size: 18, color: AppTheme.primaryPurple),
                    SizedBox(width: 6),
                    Text(
                      'EDITAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryPurple,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        state.categories.isEmpty
            ? _buildRetryButton(context)
            : state.selectedCategoryIds.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Ninguna seleccionada. Pulsa EDITAR.',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            : Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: state.categories
                      .where(
                        (cat) => state.selectedCategoryIds.contains(cat.id),
                      )
                      .map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppTheme.accentBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white10),
        _buildSwitchOption(
          title: 'MODO JUNIOR',
          subtitle: 'Simplifica los términos para cadetes jóvenes.',
          value: state.juniorMode,
          onChanged: (v) => context.read<SetupCubit>().toggleJunior(v),
        ),
        _buildSwitchOption(
          title: 'MODO SUPERVIVENCIA',
          subtitle: 'Elimina jugadores que fallen.',
          value: state.survivalMode,
          onChanged: (v) => context.read<SetupCubit>().toggleSurvival(v),
        ),
        _buildSwitchOption(
          title: 'TEMPORIZADOR',
          subtitle: 'Segundos disponibles para cada turno',
          value: state.timerEnabled,
          onChanged: (v) => context.read<SetupCubit>().toggleTimer(v),
        ),
        if (state.timerEnabled) _buildTimerSelector(context, state),
      ],
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppTheme.primaryPurple,
                  activeTrackColor: AppTheme.primaryPurple.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSelector(BuildContext context, SetupState state) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [15, 30, 60].map((sec) {
          final isSelected = state.timerSeconds == sec;
          return Expanded(
            child: GestureDetector(
              onTap: () => context.read<SetupCubit>().setTimerSeconds(sec),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  '${sec}S',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.white24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text(
            'No se han podido cargar las categorías',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.read<SetupCubit>().loadCategories(),
            icon: const Icon(Icons.refresh),
            label: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, SetupState state) {
    if (state.status is SetupLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final canCreate = state.selectedCategoryIds.isNotEmpty;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: canCreate ? AppTheme.buttonLavender : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            boxShadow: canCreate
                ? [
                    BoxShadow(
                      color: AppTheme.buttonLavender.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: !canCreate
                ? null
                : () {
                    context.read<SetupCubit>().updateIsCreating(true);
                    context.read<SetupCubit>().proceedToProfileSelection();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'CREAR PARTIDA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: canCreate ? Colors.black87 : Colors.white24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _gameIdController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'CODIGO',
                    hintStyle: TextStyle(
                      letterSpacing: 2,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 64,
              width: 140,
              decoration: BoxDecoration(
                color: AppTheme.buttonLavender,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.buttonLavender.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final code = _gameIdController.text;
                  if (code.isNotEmpty) {
                    context.read<SetupCubit>().updateIsCreating(false);
                    context.read<SetupCubit>().startJoiningWithCode(code);
                  }
                },
                child: const Text(
                  'UNIRSE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCategorySelectionSheet(BuildContext context, SetupState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<SetupCubit>(),
          child: BlocBuilder<SetupCubit, SetupState>(
            builder: (context, sheetState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                'SELECCIONAR CATEGORÍAS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Escoge los mundos para jugar.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              for (final cat in sheetState.categories) {
                                // If Junior Mode is on and category is not allowed, ignore it
                                if (sheetState.juniorMode && !cat.isJuniorAvailable) continue;
                                if (!sheetState.selectedCategoryIds.contains(
                                  cat.id,
                                )) {
                                  context.read<SetupCubit>().toggleCategory(
                                    cat.id,
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'TODO',
                              style: TextStyle(
                                color: AppTheme.accentBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: sheetState.categories.length,
                        itemBuilder: (context, index) {
                          final cat = sheetState.categories[index];
                          final isSelected = sheetState.selectedCategoryIds
                              .contains(cat.id);
                          final isJuniorAllowed = cat.isJuniorAvailable;
                          final isDisabled = sheetState.juniorMode && !isJuniorAllowed;

                          return GestureDetector(
                            onTap: isDisabled
                                ? null
                                : () => context
                                    .read<SetupCubit>()
                                    .toggleCategory(cat.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentBlue.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accentBlue.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                              child: Opacity(
                                opacity: isDisabled ? 0.3 : 1.0,
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      size: 16,
                                      color: isSelected
                                          ? AppTheme.accentBlue
                                          : Colors.white10,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        cat.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppTheme.accentBlue
                                              : Colors.white60,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text('LISTO PROTOCOLOS'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
