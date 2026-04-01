import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class SonarrTag {
  const SonarrTag({required this.id, required this.label});

  final int id;
  final String label;

  factory SonarrTag.fromJson(Map<String, dynamic> json) =>
      _$SonarrTagFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrTagToJson(this);
}
