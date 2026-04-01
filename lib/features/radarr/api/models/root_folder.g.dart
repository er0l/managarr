// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'root_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarrRootFolder _$RadarrRootFolderFromJson(Map<String, dynamic> json) =>
    RadarrRootFolder(
      id: (json['id'] as num).toInt(),
      path: json['path'] as String,
      freeSpace: (json['freeSpace'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RadarrRootFolderToJson(RadarrRootFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'freeSpace': instance.freeSpace,
    };
