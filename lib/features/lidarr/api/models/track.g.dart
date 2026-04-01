// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrTrack _$LidarrTrackFromJson(Map<String, dynamic> json) => LidarrTrack(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  trackNumber: json['trackNumber'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  explicit: json['explicit'] as bool?,
  hasFile: json['hasFile'] as bool?,
  monitored: json['monitored'] as bool?,
  artistId: (json['artistId'] as num?)?.toInt(),
  albumId: (json['albumId'] as num?)?.toInt(),
);

Map<String, dynamic> _$LidarrTrackToJson(LidarrTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'trackNumber': instance.trackNumber,
      'duration': instance.duration,
      'explicit': instance.explicit,
      'hasFile': instance.hasFile,
      'monitored': instance.monitored,
      'artistId': instance.artistId,
      'albumId': instance.albumId,
    };
