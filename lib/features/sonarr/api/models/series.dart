import 'package:json_annotation/json_annotation.dart';

part 'series.g.dart';

@JsonSerializable(explicitToJson: true)
class SonarrSeries {
  const SonarrSeries({
    @JsonKey(defaultValue: 0) this.id = 0,
    required this.title,
    @JsonKey(defaultValue: false) this.monitored = false,
    this.year,
    this.status,
    this.seasonCount,
    this.overview,
    this.network,
    this.runtime,
    this.sortTitle,
    this.added,
    this.seriesType,
    this.qualityProfileId,
    this.nextAiring,
    this.previousAiring,
    this.statistics,
    this.images,
    this.seasons,
    this.tvdbId,
    this.imdbId,
    this.tvMazeId,
    this.tmdbId,
    this.path,
    this.rootFolderPath,
    this.tags,
  });

  @JsonKey(defaultValue: 0)
  final int id;
  final String title;
  @JsonKey(defaultValue: false)
  final bool monitored;
  final int? year;

  /// e.g. 'continuing', 'ended'
  final String? status;
  final int? seasonCount;
  final String? overview;
  final String? network;
  final int? runtime;
  final String? sortTitle;
  final DateTime? added;
  final String? seriesType;
  final int? qualityProfileId;
  final DateTime? nextAiring;
  final DateTime? previousAiring;
  final SonarrStatistics? statistics;

  final List<SonarrImage>? images;
  final List<SonarrSeason>? seasons;
  final int? tvdbId;
  final String? imdbId;
  final int? tvMazeId;

  /// TV show TMDB ID — present in Sonarr v4+, null on v3.
  final int? tmdbId;
  final String? path;
  final String? rootFolderPath;
  final List<int>? tags;

  String? get posterUrl => images
      ?.where((i) => i.coverType == 'poster')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  String? get fanartUrl => images
      ?.where((i) => i.coverType == 'fanart')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  String? get bannerUrl => images
      ?.where((i) => i.coverType == 'banner')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  factory SonarrSeries.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrSeriesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SonarrSeason {
  const SonarrSeason({
    required this.seasonNumber,
    required this.monitored,
    this.statistics,
  });

  final int seasonNumber;
  final bool monitored;
  final SonarrStatistics? statistics;

  factory SonarrSeason.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeasonFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrSeasonToJson(this);
}

@JsonSerializable()
class SonarrImage {
  const SonarrImage({required this.coverType, this.remoteUrl});

  final String coverType;
  final String? remoteUrl;

  factory SonarrImage.fromJson(Map<String, dynamic> json) =>
      _$SonarrImageFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SonarrStatistics {
  const SonarrStatistics({
    this.episodeFileCount,
    this.episodeCount,
    this.totalEpisodeCount,
    this.sizeOnDisk,
    this.percentOfEpisodes,
  });

  final int? episodeFileCount;
  final int? episodeCount;
  final int? totalEpisodeCount;
  final int? sizeOnDisk;
  final double? percentOfEpisodes;

  factory SonarrStatistics.fromJson(Map<String, dynamic> json) =>
      _$SonarrStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrStatisticsToJson(this);
}
