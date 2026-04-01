// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrHistory _$SonarrHistoryFromJson(Map<String, dynamic> json) =>
    SonarrHistory(
      records: (json['records'] as List<dynamic>)
          .map((e) => SonarrHistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecords: (json['totalRecords'] as num).toInt(),
    );

Map<String, dynamic> _$SonarrHistoryToJson(SonarrHistory instance) =>
    <String, dynamic>{
      'records': instance.records.map((e) => e.toJson()).toList(),
      'totalRecords': instance.totalRecords,
    };

SonarrHistoryRecord _$SonarrHistoryRecordFromJson(Map<String, dynamic> json) =>
    SonarrHistoryRecord(
      id: (json['id'] as num?)?.toInt(),
      seriesId: (json['seriesId'] as num?)?.toInt(),
      episodeId: (json['episodeId'] as num?)?.toInt(),
      sourceTitle: json['sourceTitle'] as String?,
      date: DateTime.parse(json['date'] as String),
      eventType: json['eventType'] as String,
      series: json['series'] == null
          ? null
          : SonarrSeries.fromJson(json['series'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SonarrHistoryRecordToJson(
  SonarrHistoryRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'seriesId': instance.seriesId,
  'episodeId': instance.episodeId,
  'sourceTitle': instance.sourceTitle,
  'date': instance.date.toIso8601String(),
  'eventType': instance.eventType,
  'series': instance.series?.toJson(),
};
