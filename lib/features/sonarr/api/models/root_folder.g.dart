// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'root_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonarrRootFolder _$SonarrRootFolderFromJson(Map<String, dynamic> json) =>
    SonarrRootFolder(
      id: (json['id'] as num).toInt(),
      path: json['path'] as String,
      freeSpace: (json['freeSpace'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SonarrRootFolderToJson(SonarrRootFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'freeSpace': instance.freeSpace,
    };
