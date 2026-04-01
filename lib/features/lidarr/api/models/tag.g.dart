// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrTag _$LidarrTagFromJson(Map<String, dynamic> json) => LidarrTag(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
    );

Map<String, dynamic> _$LidarrTagToJson(LidarrTag instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
    };
