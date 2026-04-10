// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
  id: json['id'] as String,
  name: json['name'] as String,
  avatarId: json['avatar_id'] as String,
  isHost: json['is_host'] as bool? ?? false,
  isReady: json['is_ready'] as bool? ?? false,
  isAlive: json['is_alive'] as bool? ?? true,
  isImpostor: json['is_impostor'] as bool? ?? false,
  orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
  hasVoted: json['has_voted'] as bool? ?? false,
  hasDecided: json['has_decided'] as bool? ?? false,
  wantsToVote: json['wants_to_vote'] as bool? ?? false,
  voteTargetId: json['vote_target_id'] as String?,
);

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar_id': instance.avatarId,
  'is_host': instance.isHost,
  'is_ready': instance.isReady,
  'is_alive': instance.isAlive,
  'is_impostor': instance.isImpostor,
  'order_index': instance.orderIndex,
  'has_voted': instance.hasVoted,
  'has_decided': instance.hasDecided,
  'wants_to_vote': instance.wantsToVote,
  'vote_target_id': instance.voteTargetId,
};
