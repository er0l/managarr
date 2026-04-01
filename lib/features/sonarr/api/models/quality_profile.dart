import 'package:json_annotation/json_annotation.dart';

part 'quality_profile.g.dart';

@JsonSerializable()
class SonarrQualityProfile {
  const SonarrQualityProfile({required this.id, required this.name});

  final int id;
  final String name;

  factory SonarrQualityProfile.fromJson(Map<String, dynamic> json) =>
      _$SonarrQualityProfileFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrQualityProfileToJson(this);
}
