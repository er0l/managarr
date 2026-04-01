// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarrQueue _$RadarrQueueFromJson(Map<String, dynamic> json) => RadarrQueue(
  page: (json['page'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalRecords: (json['totalRecords'] as num).toInt(),
  records: (json['records'] as List<dynamic>)
      .map((e) => RadarrQueueRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
);

RadarrQueueRecord _$RadarrQueueRecordFromJson(Map<String, dynamic> json) =>
    RadarrQueueRecord(
      id: (json['id'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      title: json['title'] as String,
      size: (json['size'] as num).toDouble(),
      sizeleft: (json['sizeleft'] as num).toDouble(),
      status: json['status'] as String,
      trackedDownloadStatus: json['trackedDownloadStatus'] as String?,
      trackedDownloadState: json['trackedDownloadState'] as String?,
      downloadId: json['downloadId'] as String?,
      protocol: json['protocol'] as String?,
      estimatedCompletionTime: json['estimatedCompletionTime'] == null
          ? null
          : DateTime.parse(json['estimatedCompletionTime'] as String),
    );
