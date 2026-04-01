// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'root_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LidarrRootFolder _$LidarrRootFolderFromJson(Map<String, dynamic> json) =>
    LidarrRootFolder(
      id: (json['id'] as num).toInt(),
      path: json['path'] as String,
      freeSpace: (json['freeSpace'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LidarrRootFolderToJson(LidarrRootFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'freeSpace': instance.freeSpace,
    };
