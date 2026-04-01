import 'package:json_annotation/json_annotation.dart';

part 'release.g.dart';

@JsonSerializable(createToJson: false)
class SonarrRelease {
  const SonarrRelease({
    required this.guid,
    required this.title,
    required this.approved,
    required this.rejected,
    this.quality,
    this.size,
    this.indexer,
    this.seeders,
    this.leechers,
    this.protocol,
    this.rejections,
    this.age,
    this.ageHours,
    this.customFormatScore,
    this.infoUrl,
    this.indexerId,
  });

  final String guid;
  final String title;
  final bool approved;
  final bool rejected;
  final Map<String, dynamic>? quality;
  final int? size;
  final String? indexer;
  final int? seeders;
  final int? leechers;
  final String? protocol;
  final List<String>? rejections;
  final int? age;
  final double? ageHours;
  final int? customFormatScore;
  final String? infoUrl;
  final int? indexerId;

  String get qualityName {
    try {
      return (quality?['quality'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  factory SonarrRelease.fromJson(Map<String, dynamic> json) =>
      _$SonarrReleaseFromJson(json);
}
