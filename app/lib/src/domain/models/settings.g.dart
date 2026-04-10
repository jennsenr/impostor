// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
  categoryIds: (json['category_ids'] as List<dynamic>).map((e) => e as String).toList(),
  juniorMode: json['junior_mode'] as bool? ?? false,
  survivalMode: json['survival_mode'] as bool? ?? false,
  timerEnabled: json['timer_enabled'] as bool? ?? false,
  timerSeconds: (json['timer_seconds'] as num?)?.toInt() ?? 60,
);

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'category_ids': instance.categoryIds,
  'junior_mode': instance.juniorMode,
  'survival_mode': instance.survivalMode,
  'timer_enabled': instance.timerEnabled,
  'timer_seconds': instance.timerSeconds,
};
