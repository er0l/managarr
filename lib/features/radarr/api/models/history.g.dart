// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarrHistory _$RadarrHistoryFromJson(Map<String, dynamic> json) =>
    RadarrHistory(
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      totalRecords: (json['totalRecords'] as num).toInt(),
      records: (json['records'] as List<dynamic>)
          .map((e) => RadarrHistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

RadarrHistoryRecord _$RadarrHistoryRecordFromJson(Map<String, dynamic> json) =>
    RadarrHistoryRecord(
      id: (json['id'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      sourceTitle: json['sourceTitle'] as String,
      eventType: json['eventType'] as String,
      date: DateTime.parse(json['date'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
