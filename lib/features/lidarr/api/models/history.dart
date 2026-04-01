import 'package:json_annotation/json_annotation.dart';

part 'history.g.dart';

@JsonSerializable(explicitToJson: true)
class LidarrHistory {
  const LidarrHistory({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.records,
  });

  final int page;
  final int pageSize;
  final int totalRecords;
  final List<LidarrHistoryRecord> records;

  factory LidarrHistory.fromJson(Map<String, dynamic> json) =>
      _$LidarrHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrHistoryToJson(this);
}

@JsonSerializable()
class LidarrHistoryRecord {
  const LidarrHistoryRecord({
    required this.id,
    this.artistId,
    this.albumId,
    this.sourceTitle,
    this.quality,
    this.date,
    this.eventType,
    this.data,
  });

  final int id;
  final int? artistId;
  final int? albumId;
  final String? sourceTitle;
  final LidarrHistoryQuality? quality;
  final DateTime? date;
  final String? eventType;
  final Map<String, dynamic>? data;

  factory LidarrHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$LidarrHistoryRecordFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrHistoryRecordToJson(this);
}

@JsonSerializable()
class LidarrHistoryQuality {
  const LidarrHistoryQuality({this.quality});

  final LidarrQualityDetails? quality;

  factory LidarrHistoryQuality.fromJson(Map<String, dynamic> json) =>
      _$LidarrHistoryQualityFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrHistoryQualityToJson(this);
}

@JsonSerializable()
class LidarrQualityDetails {
  const LidarrQualityDetails({this.name});

  final String? name;

  factory LidarrQualityDetails.fromJson(Map<String, dynamic> json) =>
      _$LidarrQualityDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrQualityDetailsToJson(this);
}
