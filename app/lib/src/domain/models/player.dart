import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Player {
  final String id;
  final String name;
  final String avatarId;
  final bool isConnected;
  final bool isHost;
  final bool isReady;
  final bool isAlive;
  final bool isImpostor;
  final int orderIndex;
  final bool hasVoted;
  final bool hasDecided;
  final bool wantsToVote;
  final String? voteTargetId;
  final bool adCompleted;

  Player({
    required this.id,
    required this.name,
    required this.avatarId,
    this.isConnected = true,
    this.isHost = false,
    this.isReady = false,
    this.isAlive = true,
    this.isImpostor = false,
    this.orderIndex = 0,
    this.hasVoted = false,
    this.hasDecided = false,
    this.wantsToVote = false,
    this.voteTargetId,
    this.adCompleted = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  Player copyWith({
    String? id,
    String? name,
    String? avatarId,
    bool? isConnected,
    bool? isHost,
    bool? isReady,
    bool? isAlive,
    bool? isImpostor,
    int? orderIndex,
    bool? hasVoted,
    bool? hasDecided,
    bool? wantsToVote,
    String? voteTargetId,
    bool? adCompleted,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      isConnected: isConnected ?? this.isConnected,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      isAlive: isAlive ?? this.isAlive,
      isImpostor: isImpostor ?? this.isImpostor,
      orderIndex: orderIndex ?? this.orderIndex,
      hasVoted: hasVoted ?? this.hasVoted,
      hasDecided: hasDecided ?? this.hasDecided,
      wantsToVote: wantsToVote ?? this.wantsToVote,
      voteTargetId: voteTargetId ?? this.voteTargetId,
      adCompleted: adCompleted ?? this.adCompleted,
    );
  }
}
