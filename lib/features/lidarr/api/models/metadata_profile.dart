import 'package:json_annotation/json_annotation.dart';

part 'metadata_profile.g.dart';

@JsonSerializable()
class LidarrMetadataProfile {
  const LidarrMetadataProfile({required this.id, required this.name});

  final int id;
  final String name;

  factory LidarrMetadataProfile.fromJson(Map<String, dynamic> json) =>
      _$LidarrMetadataProfileFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrMetadataProfileToJson(this);
}
