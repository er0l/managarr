import 'package:json_annotation/json_annotation.dart';

part 'quality_profile.g.dart';

@JsonSerializable()
class LidarrQualityProfile {
  const LidarrQualityProfile({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory LidarrQualityProfile.fromJson(Map<String, dynamic> json) =>
      _$LidarrQualityProfileFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrQualityProfileToJson(this);
}
