// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrRelease _$SonarrReleaseFromJson(Map<String, dynamic> json) =>
    SonarrRelease(
      guid: json['guid'] as String,
      title: json['title'] as String,
      approved: json['approved'] as bool,
      rejected: json['rejected'] as bool,
      quality: json['quality'] as Map<String, dynamic>?,
      size: (json['size'] as num?)?.toInt(),
      indexer: json['indexer'] as String?,
      seeders: (json['seeders'] as num?)?.toInt(),
      leechers: (json['leechers'] as num?)?.toInt(),
      protocol: json['protocol'] as String?,
      rejections: (json['rejections'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      age: (json['age'] as num?)?.toInt(),
      ageHours: (json['ageHours'] as num?)?.toDouble(),
      customFormatScore: (json['customFormatScore'] as num?)?.toInt(),
      infoUrl: json['infoUrl'] as String?,
      indexerId: (json['indexerId'] as num?)?.toInt(),
    );
