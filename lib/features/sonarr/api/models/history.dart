import 'package:json_annotation/json_annotation.dart';
import 'series.dart';

part 'history.g.dart';

@JsonSerializable(explicitToJson: true)
class SonarrHistory {
  const SonarrHistory({
    required this.records,
    required this.totalRecords,
  });

  final List<SonarrHistoryRecord> records;
  final int totalRecords;

  factory SonarrHistory.fromJson(Map<String, dynamic> json) =>
      _$SonarrHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrHistoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SonarrHistoryRecord {
  const SonarrHistoryRecord({
    this.id,
    this.seriesId,
    this.episodeId,
    this.sourceTitle,
    required this.date,
    required this.eventType,
    this.series,
  });

  final int? id;
  final int? seriesId;
  final int? episodeId;
  final String? sourceTitle;
  final DateTime date;
  final String eventType;
  final SonarrSeries? series;

  factory SonarrHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$SonarrHistoryRecordFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrHistoryRecordToJson(this);
}
