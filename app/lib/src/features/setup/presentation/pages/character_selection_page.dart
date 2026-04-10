import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../cubit/setup_cubit.dart';
import '../cubit/setup_state.dart';

class CharacterSelectionPage extends StatefulWidget {
  const CharacterSelectionPage({super.key});

  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  final TextEditingController _nameController = TextEditingController();

  void _handleBack(BuildContext context) {
    context.read<SetupCubit>().backToSettings();
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = context.read<SetupCubit>().state.playerName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupCubit, SetupState>(
      listener: (context, state) {
        if (state.status is SetupError) {
          final error = state.status as SetupError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_setupErrorMessage(error.message))),
          );
        }
      },
      builder: (context, state) {
        final isCreating = state.isCreating;
        final pendingCode = state.pendingGameId;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && context.mounted) {
              _handleBack(context);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _handleBack(context),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            extendBodyBehindAppBar: true,
            body: Container(
              constraints: const BoxConstraints.expand(),
              decoration: const BoxDecoration(color: AppTheme.backgroundDark),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const _FuturisticHeader(),
                      const SizedBox(height: 32),
                      _buildJoinInfo(pendingCode, isCreating),
                      // Card-like container for the selection UI
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
                            _buildNameInput(context, state),
                            const SizedBox(height: 32),
                            _buildAvatarGrid(context, state),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: state.avatarId.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildActionButton(context, state),
                  ),
          ),
        );
      },
    );
  }

  String _setupErrorMessage(String code) {
    switch (code) {
      case 'name_required':
        return 'Introduce tu nombre antes de continuar.';
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

  Widget _buildJoinInfo(String? code, bool isCreating) {
    if (isCreating || code == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sensors, size: 16, color: AppTheme.accentBlue),
          const SizedBox(width: 8),
          Text(
            'CANAL DE VINCULACIÓN: $code',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput(BuildContext context, SetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOMBRE DEL TRIPULANTE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          enabled: state.status is! SetupLoading,
          onChanged: (v) => context.read<SetupCubit>().updateName(v),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
          decoration: InputDecoration(
            hintText: 'INTRODUCE NOMBRE...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            fillColor: Colors.black.withOpacity(0.4),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarGrid(BuildContext context, SetupState state) {    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 15,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85, // Adjust for label space
      ),
      itemBuilder: (context, index) {
        final id = (index + 1).toString();
        final isSelected = state.avatarId == id;
        final isOccupied = state.occupiedAvatarIds.contains(id);

        String statusLabel = 'DISPONIBLE';
        Color statusColor = AppTheme.availableGray;

        if (isSelected) {
          statusLabel = 'SELECCIONADO';
          statusColor = AppTheme.primaryPurple;
        } else if (isOccupied) {
          statusLabel = 'OCUPADO';
          statusColor = AppTheme.occupiedRed;
        }

        return GestureDetector(
          onTap: isOccupied
              ? null
              : () => context.read<SetupCubit>().updateAvatar(id),
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryPurple.withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryPurple : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColorFiltered(
                              colorFilter: isOccupied
                                  ? ColorFilter.mode(
                                      Colors.red.withOpacity(0.4),
                                      BlendMode.color,
                                    )
                                  : const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.multiply,
                                    ),
                              child: Opacity(
                                opacity: isOccupied ? 0.5 : 1.0,
                                child: Image.asset(
                                  'assets/images/avatars/avatar_$id.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Text(
                                      'A$id',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppTheme.primaryPurple
                                            : Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isOccupied)
                            Center(
                              child: Icon(
                                Icons.lock_outline,
                                color: Colors.red.withOpacity(0.8),
                                size: 32,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: statusColor,
                ),
              ),
            ],
          ),
        );
      },
    );

  }

  Widget _buildActionButton(BuildContext context, SetupState state) {
    final isCreating = state.isCreating;
    final isLoading = state.status is SetupLoading;

    final canProceed =
        state.playerName.isNotEmpty &&
        (!isCreating || state.selectedCategoryIds.isNotEmpty);

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.buttonLavender,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.buttonLavender.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (isLoading || !canProceed)
            ? null
            : () {
                if (state.status is SetupSuccess) {
                  final s = state.status as SetupSuccess;
                  context.read<SetupCubit>().rejoinGame(s.game.code);
                } else if (isCreating) {
                  context.read<SetupCubit>().createGame();
                } else if (state.pendingGameId != null) {
                  context.read<SetupCubit>().joinGame(state.pendingGameId!);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black87,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(state.status is SetupSuccess ? Icons.refresh : Icons.link, color: Colors.black87, size: 24),
                  const SizedBox(width: 16),
                  Text(
                    state.status is SetupSuccess ? 'ACTUALIZAR AVATAR' : 'VINCULAR AVATAR',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FuturisticHeader extends StatelessWidget {
  const _FuturisticHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'SELECCIONAR\nAVATAR',
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
          'SELECCIONA TU AVATAR DE TRIPULACIÓN',
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
}
