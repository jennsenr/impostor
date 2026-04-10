import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Category {
  final String id;
  final String name;
  final bool isJuniorAvailable;

  Category({
    required this.id,
    required this.name,
    required this.isJuniorAvailable,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
