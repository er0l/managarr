import 'package:json_annotation/json_annotation.dart';

part 'queue.g.dart';

@JsonSerializable(explicitToJson: true)
class LidarrQueue {
  const LidarrQueue({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.records,
  });

  final int page;
  final int pageSize;
  final int totalRecords;
  final List<LidarrQueueRecord> records;

  factory LidarrQueue.fromJson(Map<String, dynamic> json) =>
      _$LidarrQueueFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrQueueToJson(this);
}

@JsonSerializable()
class LidarrQueueRecord {
  const LidarrQueueRecord({
    required this.id,
    this.artistId,
    this.albumId,
    this.title,
    this.size,
    this.sizeleft,
    this.status,
    this.trackedDownloadStatus,
    this.trackedDownloadState,
    this.statusMessages,
    this.errorMessage,
  });

  final int id;
  final int? artistId;
  final int? albumId;
  final String? title;
  final double? size;
  final double? sizeleft;
  final String? status;
  final String? trackedDownloadStatus;
  final String? trackedDownloadState;
  final List<LidarrQueueStatusMessage>? statusMessages;
  final String? errorMessage;

  factory LidarrQueueRecord.fromJson(Map<String, dynamic> json) =>
      _$LidarrQueueRecordFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrQueueRecordToJson(this);
}

@JsonSerializable()
class LidarrQueueStatusMessage {
  const LidarrQueueStatusMessage({this.title, this.messages});

  final String? title;
  final List<String>? messages;

  factory LidarrQueueStatusMessage.fromJson(Map<String, dynamic> json) =>
      _$LidarrQueueStatusMessageFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrQueueStatusMessageToJson(this);
}
