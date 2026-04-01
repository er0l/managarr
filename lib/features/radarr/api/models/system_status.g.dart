// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarrSystemStatus _$RadarrSystemStatusFromJson(Map<String, dynamic> json) =>
    RadarrSystemStatus(
      version: json['version'] as String,
      startupPath: json['startupPath'] as String?,
      appData: json['appData'] as String?,
      osVersion: json['osVersion'] as String?,
      runtimeVersion: json['runtimeVersion'] as String?,
      isDebug: json['isDebug'] as bool?,
      isLinux: json['isLinux'] as bool?,
      isOsx: json['isOsx'] as bool?,
      isWindows: json['isWindows'] as bool?,
    );

Map<String, dynamic> _$RadarrSystemStatusToJson(RadarrSystemStatus instance) =>
    <String, dynamic>{
      'version': instance.version,
      'startupPath': instance.startupPath,
      'appData': instance.appData,
      'osVersion': instance.osVersion,
      'runtimeVersion': instance.runtimeVersion,
      'isDebug': instance.isDebug,
      'isLinux': instance.isLinux,
      'isOsx': instance.isOsx,
      'isWindows': instance.isWindows,
    };
