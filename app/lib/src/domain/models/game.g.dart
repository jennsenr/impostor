// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Game _$GameFromJson(Map<String, dynamic> json) => Game(
  id: json['id'] as String,
  code: json['code'] as String,
  status: $enumDecode(_$GameStatusEnumMap, json['status']),
  players: (json['players'] as List<dynamic>)
      .map((e) => Player.fromJson(e as Map<String, dynamic>))
      .toList(),
  settings: Settings.fromJson(json['settings'] as Map<String, dynamic>),
  currentRound: (json['current_round'] as num).toInt(),
  currentTurnIndex: (json['current_turn_index'] as num).toInt(),
  word: json['word'] as String,
  wordImageURL: json['word_image_url'] as String?,
  hostId: json['host_id'] as String,
  hostIsPremium: json['host_is_premium'] as bool,
  winnerTeam: json['winner_team'] as String?,
  expelledId: json['expelled_id'] as String?,
  starterIndex: (json['starter_index'] as num?)?.toInt() ?? 0,
  activeCategoryId: json['active_category_id'] as String?,
  activeCategoryName: json['active_category_name'] as String?,
);

Map<String, dynamic> _$GameToJson(Game instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'status': _$GameStatusEnumMap[instance.status]!,
  'players': instance.players,
  'settings': instance.settings,
  'current_round': instance.currentRound,
  'current_turn_index': instance.currentTurnIndex,
  'word': instance.word,
  'word_image_url': instance.wordImageURL,
  'host_id': instance.hostId,
  'host_is_premium': instance.hostIsPremium,
  'winner_team': instance.winnerTeam,
  'expelled_id': instance.expelledId,
  'starter_index': instance.starterIndex,
  'active_category_id': instance.activeCategoryId,
  'active_category_name': instance.activeCategoryName,
};

const _$GameStatusEnumMap = {
  GameStatus.waiting: 'WAITING',
  GameStatus.adPhase: 'AD_PHASE',
  GameStatus.ready: 'READY',
  GameStatus.playing: 'PLAYING',
  GameStatus.decision: 'DECISION',
  GameStatus.voting: 'VOTING',
  GameStatus.result: 'RESULT',
  GameStatus.finished: 'FINISHED',
};
