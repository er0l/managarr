// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrCalendar _$SonarrCalendarFromJson(Map<String, dynamic> json) =>
    SonarrCalendar(
      id: (json['id'] as num?)?.toInt(),
      seriesId: (json['seriesId'] as num?)?.toInt(),
      episodeFileId: (json['episodeFileId'] as num?)?.toInt(),
      seasonNumber: (json['seasonNumber'] as num?)?.toInt(),
      episodeNumber: (json['episodeNumber'] as num?)?.toInt(),
      title: json['title'] as String?,
      airDate: json['airDate'] as String?,
      airDateUtc: json['airDateUtc'] == null
          ? null
          : DateTime.parse(json['airDateUtc'] as String),
      overview: json['overview'] as String?,
      hasFile: json['hasFile'] as bool?,
      monitored: json['monitored'] as bool?,
      series: json['series'] == null
          ? null
          : SonarrSeries.fromJson(json['series'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => SonarrImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      qualityName: (((json['episodeFile'] as Map<String, dynamic>?)?['quality']
            as Map<String, dynamic>?)?['quality']
            as Map<String, dynamic>?)?['name'] as String?,
    );

Map<String, dynamic> _$SonarrCalendarToJson(SonarrCalendar instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seriesId': instance.seriesId,
      'episodeFileId': instance.episodeFileId,
      'seasonNumber': instance.seasonNumber,
      'episodeNumber': instance.episodeNumber,
      'title': instance.title,
      'airDate': instance.airDate,
      'airDateUtc': instance.airDateUtc?.toIso8601String(),
      'overview': instance.overview,
      'hasFile': instance.hasFile,
      'monitored': instance.monitored,
      'series': instance.series?.toJson(),
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'qualityName': instance.qualityName,
    };
