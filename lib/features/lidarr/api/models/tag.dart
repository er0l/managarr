import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class LidarrTag {
  const LidarrTag({required this.id, required this.label});

  final int id;
  final String label;

  factory LidarrTag.fromJson(Map<String, dynamic> json) =>
      _$LidarrTagFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrTagToJson(this);
}
