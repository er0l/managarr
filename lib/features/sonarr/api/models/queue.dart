import 'package:json_annotation/json_annotation.dart';
import 'series.dart';

part 'queue.g.dart';

@JsonSerializable(explicitToJson: true)
class SonarrQueue {
  const SonarrQueue({
    required this.records,
    required this.totalRecords,
  });

  final List<SonarrQueueRecord> records;
  final int totalRecords;

  factory SonarrQueue.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrQueueToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SonarrQueueRecord {
  const SonarrQueueRecord({
    this.id,
    this.seriesId,
    this.episodeId,
    this.title,
    this.size,
    this.sizeleft,
    this.status,
    this.trackedDownloadStatus,
    this.trackedDownloadState,
    this.series,
  });

  final int? id;
  final int? seriesId;
  final int? episodeId;
  final String? title;
  final double? size;
  final double? sizeleft;
  final String? status;
  final String? trackedDownloadStatus;
  final String? trackedDownloadState;
  final SonarrSeries? series;

  factory SonarrQueueRecord.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueRecordFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrQueueRecordToJson(this);
}
