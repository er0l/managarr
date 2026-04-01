// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrHistory _$LidarrHistoryFromJson(Map<String, dynamic> json) =>
    LidarrHistory(
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      totalRecords: (json['totalRecords'] as num).toInt(),
      records: (json['records'] as List<dynamic>)
          .map((e) => LidarrHistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LidarrHistoryToJson(LidarrHistory instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'totalRecords': instance.totalRecords,
      'records': instance.records.map((e) => e.toJson()).toList(),
    };

LidarrHistoryRecord _$LidarrHistoryRecordFromJson(
  Map<String, dynamic> json,
) => LidarrHistoryRecord(
  id: (json['id'] as num).toInt(),
  artistId: (json['artistId'] as num?)?.toInt(),
  albumId: (json['albumId'] as num?)?.toInt(),
  sourceTitle: json['sourceTitle'] as String?,
  quality: json['quality'] == null
      ? null
      : LidarrHistoryQuality.fromJson(json['quality'] as Map<String, dynamic>),
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  eventType: json['eventType'] as String?,
  data: json['data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$LidarrHistoryRecordToJson(
  LidarrHistoryRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'artistId': instance.artistId,
  'albumId': instance.albumId,
  'sourceTitle': instance.sourceTitle,
  'quality': instance.quality,
  'date': instance.date?.toIso8601String(),
  'eventType': instance.eventType,
  'data': instance.data,
};

LidarrHistoryQuality _$LidarrHistoryQualityFromJson(
  Map<String, dynamic> json,
) => LidarrHistoryQuality(
  quality: json['quality'] == null
      ? null
      : LidarrQualityDetails.fromJson(json['quality'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LidarrHistoryQualityToJson(
  LidarrHistoryQuality instance,
) => <String, dynamic>{'quality': instance.quality};

LidarrQualityDetails _$LidarrQualityDetailsFromJson(
  Map<String, dynamic> json,
) => LidarrQualityDetails(name: json['name'] as String?);

Map<String, dynamic> _$LidarrQualityDetailsToJson(
  LidarrQualityDetails instance,
) => <String, dynamic>{'name': instance.name};
