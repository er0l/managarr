// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarrRelease _$RadarrReleaseFromJson(Map<String, dynamic> json) =>
    RadarrRelease(
      guid: json['guid'] as String,
      title: json['title'] as String,
      quality: json['quality'] as Map<String, dynamic>?,
      size: (json['size'] as num?)?.toInt() ?? 0,
      indexer: json['indexer'] as String?,
      indexerId: (json['indexerId'] as num?)?.toInt(),
      seeders: (json['seeders'] as num?)?.toInt(),
      leechers: (json['leechers'] as num?)?.toInt(),
      protocol: json['protocol'] as String?,
      approved: json['approved'] as bool? ?? false,
      rejected: json['rejected'] as bool? ?? false,
      rejections: (json['rejections'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      age: (json['age'] as num?)?.toInt(),
      ageHours: (json['ageHours'] as num?)?.toDouble(),
      customFormatScore: (json['customFormatScore'] as num?)?.toInt(),
      infoUrl: json['infoUrl'] as String?,
    );
