import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Settings {
  final List<String> categoryIds;
  final bool juniorMode;
  final bool survivalMode;
  final bool timerEnabled;
  final int timerSeconds;

  Settings({
    required this.categoryIds,
    required this.juniorMode,
    required this.survivalMode,
    this.timerEnabled = false,
    this.timerSeconds = 60,
  });

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  Settings copyWith({
    List<String>? categoryIds,
    bool? juniorMode,
    bool? survivalMode,
    bool? timerEnabled,
    int? timerSeconds,
  }) {
    return Settings(
      categoryIds: categoryIds ?? this.categoryIds,
      juniorMode: juniorMode ?? this.juniorMode,
      survivalMode: survivalMode ?? this.survivalMode,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }
}
