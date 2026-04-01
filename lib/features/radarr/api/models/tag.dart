import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class RadarrTag {
  const RadarrTag({required this.id, required this.label});

  final int id;
  final String label;

  factory RadarrTag.fromJson(Map<String, dynamic> json) =>
      _$RadarrTagFromJson(json);

  Map<String, dynamic> toJson() => _$RadarrTagToJson(this);
}
