import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Settings {
  final List<String> categoryIds;
  final int impostorCount;
  final String language;
  final bool juniorMode;
  final bool survivalMode;
  final bool questionsMode;
  final bool timerEnabled;
  final int timerSeconds;

  Settings({
    required this.categoryIds,
    this.impostorCount = 1,
    this.language = 'es',
    required this.juniorMode,
    required this.survivalMode,
    this.questionsMode = false,
    this.timerEnabled = false,
    this.timerSeconds = 60,
  });

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  Settings copyWith({
    List<String>? categoryIds,
    int? impostorCount,
    String? language,
    bool? juniorMode,
    bool? survivalMode,
    bool? questionsMode,
    bool? timerEnabled,
    int? timerSeconds,
  }) {
    return Settings(
      categoryIds: categoryIds ?? this.categoryIds,
      impostorCount: impostorCount ?? this.impostorCount,
      language: language ?? this.language,
      juniorMode: juniorMode ?? this.juniorMode,
      survivalMode: survivalMode ?? this.survivalMode,
      questionsMode: questionsMode ?? this.questionsMode,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }
}
