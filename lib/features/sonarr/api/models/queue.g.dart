// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrQueue _$SonarrQueueFromJson(Map<String, dynamic> json) => SonarrQueue(
  records: (json['records'] as List<dynamic>)
      .map((e) => SonarrQueueRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalRecords: (json['totalRecords'] as num).toInt(),
);

Map<String, dynamic> _$SonarrQueueToJson(SonarrQueue instance) =>
    <String, dynamic>{
      'records': instance.records.map((e) => e.toJson()).toList(),
      'totalRecords': instance.totalRecords,
    };

SonarrQueueRecord _$SonarrQueueRecordFromJson(Map<String, dynamic> json) =>
    SonarrQueueRecord(
      id: (json['id'] as num?)?.toInt(),
      seriesId: (json['seriesId'] as num?)?.toInt(),
      episodeId: (json['episodeId'] as num?)?.toInt(),
      title: json['title'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      sizeleft: (json['sizeleft'] as num?)?.toDouble(),
      status: json['status'] as String?,
      trackedDownloadStatus: json['trackedDownloadStatus'] as String?,
      trackedDownloadState: json['trackedDownloadState'] as String?,
      series: json['series'] == null
          ? null
          : SonarrSeries.fromJson(json['series'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SonarrQueueRecordToJson(SonarrQueueRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seriesId': instance.seriesId,
      'episodeId': instance.episodeId,
      'title': instance.title,
      'size': instance.size,
      'sizeleft': instance.sizeleft,
      'status': instance.status,
      'trackedDownloadStatus': instance.trackedDownloadStatus,
      'trackedDownloadState': instance.trackedDownloadState,
      'series': instance.series?.toJson(),
    };
