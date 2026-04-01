// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrMetadataProfile _$LidarrMetadataProfileFromJson(
        Map<String, dynamic> json) =>
    LidarrMetadataProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$LidarrMetadataProfileToJson(
        LidarrMetadataProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
