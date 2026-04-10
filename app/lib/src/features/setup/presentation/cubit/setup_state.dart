import 'package:equatable/equatable.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/game.dart';

abstract class SetupStatus extends Equatable {
  const SetupStatus();
  @override
  List<Object?> get props => [];
}

class SetupInitial extends SetupStatus {
  const SetupInitial();
}
class SetupLoading extends SetupStatus {
  const SetupLoading();
}
class SetupError extends SetupStatus {
  final String message;
  const SetupError(this.message);
  @override
  List<Object?> get props => [message];
}
class SetupSuccess extends SetupStatus {
  final Game game;
  final String playerId;
  const SetupSuccess(this.game, this.playerId);
  @override
  List<Object?> get props => [game, playerId];
}
class SetupProfileSelection extends SetupStatus {
  const SetupProfileSelection();
}

class SetupState extends Equatable {
  final SetupStatus status;
  final List<Category> categories;
  final String playerName;
  final String avatarId;
  final List<String> selectedCategoryIds;
  final bool juniorMode;
  final bool survivalMode;
  final bool timerEnabled;
  final int timerSeconds;
  final String? pendingGameId;
  final bool isCreating;
  final List<String> occupiedAvatarIds;
  
  const SetupState({
    required this.status,
    this.categories = const [],
    this.playerName = '',
    this.avatarId = '',
    this.selectedCategoryIds = const [],
    this.juniorMode = false,
    this.survivalMode = false,
    this.timerEnabled = false,
    this.timerSeconds = 60,
    this.pendingGameId,
    this.isCreating = true,
    this.occupiedAvatarIds = const [],
  });

  SetupState copyWith({
    SetupStatus? status,
    List<Category>? categories,
    String? playerName,
    String? avatarId,
    List<String>? selectedCategoryIds,
    bool? juniorMode,
    bool? survivalMode,
    bool? timerEnabled,
    int? timerSeconds,
    String? pendingGameId,
    bool clearPendingGameId = false,
    bool? isCreating,
    List<String>? occupiedAvatarIds,
  }) {
    return SetupState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      playerName: playerName ?? this.playerName,
      avatarId: avatarId ?? this.avatarId,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      juniorMode: juniorMode ?? this.juniorMode,
      survivalMode: survivalMode ?? this.survivalMode,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      pendingGameId: clearPendingGameId ? null : (pendingGameId ?? this.pendingGameId),
      isCreating: isCreating ?? this.isCreating,
      occupiedAvatarIds: occupiedAvatarIds ?? this.occupiedAvatarIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        categories,
        playerName,
        avatarId,
        selectedCategoryIds,
        juniorMode,
        survivalMode,
        timerEnabled,
        timerSeconds,
        pendingGameId,
        isCreating,
        occupiedAvatarIds,
      ];
}
