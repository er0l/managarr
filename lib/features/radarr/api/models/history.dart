import 'package:json_annotation/json_annotation.dart';

part 'history.g.dart';

@JsonSerializable(createToJson: false)
class RadarrHistory {
  final int page;
  final int pageSize;
  final int totalRecords;
  final List<RadarrHistoryRecord> records;

  RadarrHistory({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.records,
  });

  factory RadarrHistory.fromJson(Map<String, dynamic> json) =>
      _$RadarrHistoryFromJson(json);
}

@JsonSerializable(createToJson: false)
class RadarrHistoryRecord {
  final int id;
  final int movieId;
  final String sourceTitle;
  final String eventType;
  final DateTime date;
  final Map<String, dynamic>? data;

  RadarrHistoryRecord({
    required this.id,
    required this.movieId,
    required this.sourceTitle,
    required this.eventType,
    required this.date,
    this.data,
  });

  factory RadarrHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$RadarrHistoryRecordFromJson(json);
}
