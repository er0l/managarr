import 'package:json_annotation/json_annotation.dart';

part 'release.g.dart';

@JsonSerializable(createToJson: false)
class RadarrRelease {
  const RadarrRelease({
    required this.guid,
    required this.title,
    this.quality,
    this.size,
    this.indexer,
    this.indexerId,
    this.seeders,
    this.leechers,
    this.protocol,
    this.approved = false,
    this.rejected = false,
    this.rejections,
    this.age,
    this.ageHours,
    this.customFormatScore,
    this.infoUrl,
  });

  final String guid;
  final String title;
  final Map<String, dynamic>? quality;
  @JsonKey(defaultValue: 0)
  final int? size;
  final String? indexer;
  final int? indexerId;
  final int? seeders;
  final int? leechers;
  final String? protocol;
  @JsonKey(defaultValue: false)
  final bool approved;
  @JsonKey(defaultValue: false)
  final bool rejected;
  final List<String>? rejections;
  final int? age;
  final double? ageHours;
  final int? customFormatScore;
  final String? infoUrl;

  String get qualityName {
    if (quality == null) return 'Unknown';
    final q = quality!['quality'] as Map<String, dynamic>?;
    return q?['name'] as String? ?? 'Unknown';
  }

  factory RadarrRelease.fromJson(Map<String, dynamic> json) =>
      _$RadarrReleaseFromJson(json);
}
