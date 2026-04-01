import 'package:json_annotation/json_annotation.dart';

part 'episode.g.dart';

@JsonSerializable(createToJson: false)
class SonarrEpisode {
  const SonarrEpisode({
    required this.id,
    required this.seriesId,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.title,
    required this.monitored,
    required this.hasFile,
    this.airDate,
    this.airDateUtc,
    this.overview,
    this.episodeFile,
  });

  final int id;
  final int seriesId;
  final int episodeNumber;
  final int seasonNumber;
  final String title;
  final bool monitored;
  final bool hasFile;
  final String? airDate;
  final DateTime? airDateUtc;
  final String? overview;
  final SonarrEpisodeFile? episodeFile;

  factory SonarrEpisode.fromJson(Map<String, dynamic> json) =>
      _$SonarrEpisodeFromJson(json);
}

@JsonSerializable(createToJson: false, explicitToJson: true)
class SonarrEpisodeFile {
  const SonarrEpisodeFile({
    required this.id,
    this.relativePath,
    this.size,
    this.dateAdded,
    this.quality,
    this.mediaInfo,
  });

  final int id;
  final String? relativePath;
  final int? size;
  final DateTime? dateAdded;
  final Map<String, dynamic>? quality;
  final Map<String, dynamic>? mediaInfo;

  String get qualityName {
    try {
      return (quality?['quality'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  factory SonarrEpisodeFile.fromJson(Map<String, dynamic> json) =>
      _$SonarrEpisodeFileFromJson(json);
}
