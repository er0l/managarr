// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrQueue _$LidarrQueueFromJson(Map<String, dynamic> json) => LidarrQueue(
  page: (json['page'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalRecords: (json['totalRecords'] as num).toInt(),
  records: (json['records'] as List<dynamic>)
      .map((e) => LidarrQueueRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LidarrQueueToJson(LidarrQueue instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'totalRecords': instance.totalRecords,
      'records': instance.records.map((e) => e.toJson()).toList(),
    };

LidarrQueueRecord _$LidarrQueueRecordFromJson(Map<String, dynamic> json) =>
    LidarrQueueRecord(
      id: (json['id'] as num).toInt(),
      artistId: (json['artistId'] as num?)?.toInt(),
      albumId: (json['albumId'] as num?)?.toInt(),
      title: json['title'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      sizeleft: (json['sizeleft'] as num?)?.toDouble(),
      status: json['status'] as String?,
      trackedDownloadStatus: json['trackedDownloadStatus'] as String?,
      trackedDownloadState: json['trackedDownloadState'] as String?,
      statusMessages: (json['statusMessages'] as List<dynamic>?)
          ?.map(
            (e) => LidarrQueueStatusMessage.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$LidarrQueueRecordToJson(LidarrQueueRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artistId': instance.artistId,
      'albumId': instance.albumId,
      'title': instance.title,
      'size': instance.size,
      'sizeleft': instance.sizeleft,
      'status': instance.status,
      'trackedDownloadStatus': instance.trackedDownloadStatus,
      'trackedDownloadState': instance.trackedDownloadState,
      'statusMessages': instance.statusMessages,
      'errorMessage': instance.errorMessage,
    };

LidarrQueueStatusMessage _$LidarrQueueStatusMessageFromJson(
  Map<String, dynamic> json,
) => LidarrQueueStatusMessage(
  title: json['title'] as String?,
  messages: (json['messages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$LidarrQueueStatusMessageToJson(
  LidarrQueueStatusMessage instance,
) => <String, dynamic>{'title': instance.title, 'messages': instance.messages};
