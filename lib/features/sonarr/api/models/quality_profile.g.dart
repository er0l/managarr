// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quality_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrQualityProfile _$SonarrQualityProfileFromJson(
        Map<String, dynamic> json) =>
    SonarrQualityProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$SonarrQualityProfileToJson(
        SonarrQualityProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
