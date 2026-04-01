// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrAlbum _$LidarrAlbumFromJson(Map<String, dynamic> json) => LidarrAlbum(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  monitored: json['monitored'] as bool,
  artistId: (json['artistId'] as num?)?.toInt(),
  releaseDate: DateTime.tryParse(json['releaseDate']?.toString() ?? ''),
  statistics: json['statistics'] == null
      ? null
      : LidarrAlbumStatistics.fromJson(
          json['statistics'] as Map<String, dynamic>,
        ),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => LidarrAlbumImage.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LidarrAlbumToJson(LidarrAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'monitored': instance.monitored,
      'artistId': instance.artistId,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'statistics': instance.statistics?.toJson(),
      'images': instance.images?.map((e) => e.toJson()).toList(),
    };

LidarrAlbumStatistics _$LidarrAlbumStatisticsFromJson(
  Map<String, dynamic> json,
) => LidarrAlbumStatistics(
  trackCount: (json['trackCount'] as num?)?.toInt(),
  trackFileCount: (json['trackFileCount'] as num?)?.toInt(),
  sizeOnDisk: (json['sizeOnDisk'] as num?)?.toInt(),
  percentOfTracks: (json['percentOfTracks'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LidarrAlbumStatisticsToJson(
  LidarrAlbumStatistics instance,
) => <String, dynamic>{
  'trackCount': instance.trackCount,
  'trackFileCount': instance.trackFileCount,
  'sizeOnDisk': instance.sizeOnDisk,
  'percentOfTracks': instance.percentOfTracks,
};

LidarrAlbumImage _$LidarrAlbumImageFromJson(Map<String, dynamic> json) =>
    LidarrAlbumImage(
      coverType: json['coverType'] as String,
      remoteUrl: json['remoteUrl'] as String?,
    );

Map<String, dynamic> _$LidarrAlbumImageToJson(LidarrAlbumImage instance) =>
    <String, dynamic>{
      'coverType': instance.coverType,
      'remoteUrl': instance.remoteUrl,
    };
