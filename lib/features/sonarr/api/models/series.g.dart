// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrSeries _$SonarrSeriesFromJson(Map<String, dynamic> json) => SonarrSeries(
  id: (json['id'] as num?)?.toInt() ?? 0,
  title: json['title'] as String,
  monitored: json['monitored'] as bool? ?? false,
  year: (json['year'] as num?)?.toInt(),
  status: json['status'] as String?,
  seasonCount: (json['seasonCount'] as num?)?.toInt(),
  overview: json['overview'] as String?,
  network: json['network'] as String?,
  runtime: (json['runtime'] as num?)?.toInt(),
  sortTitle: json['sortTitle'] as String?,
  added: json['added'] == null ? null : DateTime.parse(json['added'] as String),
  seriesType: json['seriesType'] as String?,
  qualityProfileId: (json['qualityProfileId'] as num?)?.toInt(),
  nextAiring: json['nextAiring'] == null
      ? null
      : DateTime.parse(json['nextAiring'] as String),
  previousAiring: json['previousAiring'] == null
      ? null
      : DateTime.parse(json['previousAiring'] as String),
  statistics: json['statistics'] == null
      ? null
      : SonarrStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => SonarrImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  seasons: (json['seasons'] as List<dynamic>?)
      ?.map((e) => SonarrSeason.fromJson(e as Map<String, dynamic>))
      .toList(),
  tvdbId: (json['tvdbId'] as num?)?.toInt(),
  path: json['path'] as String?,
  rootFolderPath: json['rootFolderPath'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
);

Map<String, dynamic> _$SonarrSeriesToJson(SonarrSeries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'monitored': instance.monitored,
      'year': instance.year,
      'status': instance.status,
      'seasonCount': instance.seasonCount,
      'overview': instance.overview,
      'network': instance.network,
      'runtime': instance.runtime,
      'sortTitle': instance.sortTitle,
      'added': instance.added?.toIso8601String(),
      'seriesType': instance.seriesType,
      'qualityProfileId': instance.qualityProfileId,
      'nextAiring': instance.nextAiring?.toIso8601String(),
      'previousAiring': instance.previousAiring?.toIso8601String(),
      'statistics': instance.statistics?.toJson(),
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'seasons': instance.seasons?.map((e) => e.toJson()).toList(),
      'tvdbId': instance.tvdbId,
      'path': instance.path,
      'rootFolderPath': instance.rootFolderPath,
      'tags': instance.tags,
    };

SonarrSeason _$SonarrSeasonFromJson(Map<String, dynamic> json) => SonarrSeason(
  seasonNumber: (json['seasonNumber'] as num).toInt(),
  monitored: json['monitored'] as bool,
  statistics: json['statistics'] == null
      ? null
      : SonarrStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SonarrSeasonToJson(SonarrSeason instance) =>
    <String, dynamic>{
      'seasonNumber': instance.seasonNumber,
      'monitored': instance.monitored,
      'statistics': instance.statistics?.toJson(),
    };

SonarrImage _$SonarrImageFromJson(Map<String, dynamic> json) => SonarrImage(
  coverType: json['coverType'] as String,
  remoteUrl: json['remoteUrl'] as String?,
);

Map<String, dynamic> _$SonarrImageToJson(SonarrImage instance) =>
    <String, dynamic>{
      'coverType': instance.coverType,
      'remoteUrl': instance.remoteUrl,
    };

SonarrStatistics _$SonarrStatisticsFromJson(Map<String, dynamic> json) =>
    SonarrStatistics(
      episodeFileCount: (json['episodeFileCount'] as num?)?.toInt(),
      episodeCount: (json['episodeCount'] as num?)?.toInt(),
      totalEpisodeCount: (json['totalEpisodeCount'] as num?)?.toInt(),
      sizeOnDisk: (json['sizeOnDisk'] as num?)?.toInt(),
      percentOfEpisodes: (json['percentOfEpisodes'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SonarrStatisticsToJson(SonarrStatistics instance) =>
    <String, dynamic>{
      'episodeFileCount': instance.episodeFileCount,
      'episodeCount': instance.episodeCount,
      'totalEpisodeCount': instance.totalEpisodeCount,
      'sizeOnDisk': instance.sizeOnDisk,
      'percentOfEpisodes': instance.percentOfEpisodes,
    };
