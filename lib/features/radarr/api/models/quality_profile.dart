import 'package:json_annotation/json_annotation.dart';

part 'quality_profile.g.dart';

@JsonSerializable()
class RadarrQualityProfile {
  const RadarrQualityProfile({required this.id, required this.name});

  final int id;
  final String name;

  factory RadarrQualityProfile.fromJson(Map<String, dynamic> json) =>
      _$RadarrQualityProfileFromJson(json);

  Map<String, dynamic> toJson() => _$RadarrQualityProfileToJson(this);
}
