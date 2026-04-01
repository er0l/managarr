// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrSystemStatus _$SonarrSystemStatusFromJson(Map<String, dynamic> json) =>
    SonarrSystemStatus(
      version: json['version'] as String,
      osVersion: json['osVersion'] as String?,
      isLinux: json['isLinux'] as bool?,
    );

Map<String, dynamic> _$SonarrSystemStatusToJson(SonarrSystemStatus instance) =>
    <String, dynamic>{
      'version': instance.version,
      'osVersion': instance.osVersion,
      'isLinux': instance.isLinux,
    };
