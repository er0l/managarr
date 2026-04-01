import 'package:json_annotation/json_annotation.dart';

part 'queue.g.dart';

@JsonSerializable(createToJson: false)
class RadarrQueue {
  final int page;
  final int pageSize;
  final int totalRecords;
  final List<RadarrQueueRecord> records;

  RadarrQueue({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.records,
  });

  factory RadarrQueue.fromJson(Map<String, dynamic> json) =>
      _$RadarrQueueFromJson(json);
}

@JsonSerializable(createToJson: false)
class RadarrQueueRecord {
  final int id;
  final int movieId;
  final String title;
  final double size;
  final double sizeleft;
  final String status;
  final String? trackedDownloadStatus;
  final String? trackedDownloadState;
  final String? downloadId;
  final String? protocol;
  final DateTime? estimatedCompletionTime;

  RadarrQueueRecord({
    required this.id,
    required this.movieId,
    required this.title,
    required this.size,
    required this.sizeleft,
    required this.status,
    this.trackedDownloadStatus,
    this.trackedDownloadState,
    this.downloadId,
    this.protocol,
    this.estimatedCompletionTime,
  });

  factory RadarrQueueRecord.fromJson(Map<String, dynamic> json) =>
      _$RadarrQueueRecordFromJson(json);
}
