// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrArtist _$LidarrArtistFromJson(Map<String, dynamic> json) => LidarrArtist(
  id: (json['id'] as num?)?.toInt() ?? 0,
  artistName: json['artistName'] as String,
  monitored: json['monitored'] as bool? ?? false,
  sortName: json['sortName'] as String?,
  overview: json['overview'] as String?,
  artistType: json['artistType'] as String?,
  path: json['path'] as String?,
  qualityProfileId: (json['qualityProfileId'] as num?)?.toInt(),
  metadataProfileId: (json['metadataProfileId'] as num?)?.toInt(),
  statistics: json['statistics'] == null
      ? null
      : LidarrStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => LidarrImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  added: json['added'] == null ? null : DateTime.parse(json['added'] as String),
  foreignArtistId: json['foreignArtistId'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
);

Map<String, dynamic> _$LidarrArtistToJson(LidarrArtist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artistName': instance.artistName,
      'monitored': instance.monitored,
      'sortName': instance.sortName,
      'overview': instance.overview,
      'artistType': instance.artistType,
      'path': instance.path,
      'qualityProfileId': instance.qualityProfileId,
      'metadataProfileId': instance.metadataProfileId,
      'statistics': instance.statistics?.toJson(),
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'added': instance.added?.toIso8601String(),
      'foreignArtistId': instance.foreignArtistId,
      'tags': instance.tags,
    };

LidarrStatistics _$LidarrStatisticsFromJson(Map<String, dynamic> json) =>
    LidarrStatistics(
      albumCount: (json['albumCount'] as num?)?.toInt(),
      trackCount: (json['trackCount'] as num?)?.toInt(),
      trackFileCount: (json['trackFileCount'] as num?)?.toInt(),
      sizeOnDisk: (json['sizeOnDisk'] as num?)?.toInt(),
      percentOfTracks: (json['percentOfTracks'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LidarrStatisticsToJson(LidarrStatistics instance) =>
    <String, dynamic>{
      'albumCount': instance.albumCount,
      'trackCount': instance.trackCount,
      'trackFileCount': instance.trackFileCount,
      'sizeOnDisk': instance.sizeOnDisk,
      'percentOfTracks': instance.percentOfTracks,
    };

LidarrImage _$LidarrImageFromJson(Map<String, dynamic> json) => LidarrImage(
  coverType: json['coverType'] as String,
  remoteUrl: json['remoteUrl'] as String?,
);

Map<String, dynamic> _$LidarrImageToJson(LidarrImage instance) =>
    <String, dynamic>{
      'coverType': instance.coverType,
      'remoteUrl': instance.remoteUrl,
    };
