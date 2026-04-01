// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrEpisode _$SonarrEpisodeFromJson(Map<String, dynamic> json) =>
    SonarrEpisode(
      id: (json['id'] as num).toInt(),
      seriesId: (json['seriesId'] as num).toInt(),
      episodeNumber: (json['episodeNumber'] as num).toInt(),
      seasonNumber: (json['seasonNumber'] as num).toInt(),
      title: json['title'] as String,
      monitored: json['monitored'] as bool,
      hasFile: json['hasFile'] as bool,
      airDate: json['airDate'] as String?,
      airDateUtc: json['airDateUtc'] == null
          ? null
          : DateTime.parse(json['airDateUtc'] as String),
      overview: json['overview'] as String?,
      episodeFile: json['episodeFile'] == null
          ? null
          : SonarrEpisodeFile.fromJson(
              json['episodeFile'] as Map<String, dynamic>),
    );

SonarrEpisodeFile _$SonarrEpisodeFileFromJson(Map<String, dynamic> json) =>
    SonarrEpisodeFile(
      id: (json['id'] as num).toInt(),
      relativePath: json['relativePath'] as String?,
      size: (json['size'] as num?)?.toInt(),
      dateAdded: json['dateAdded'] == null
          ? null
          : DateTime.parse(json['dateAdded'] as String),
      quality: json['quality'] as Map<String, dynamic>?,
      mediaInfo: json['mediaInfo'] as Map<String, dynamic>?,
    );
