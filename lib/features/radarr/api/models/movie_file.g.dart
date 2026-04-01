// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarrMovieFile _$RadarrMovieFileFromJson(Map<String, dynamic> json) =>
    RadarrMovieFile(
      id: (json['id'] as num).toInt(),
      relativePath: json['relativePath'] as String?,
      size: (json['size'] as num?)?.toInt() ?? 0,
      dateAdded: json['dateAdded'] == null
          ? null
          : DateTime.parse(json['dateAdded'] as String),
      quality: json['quality'] as Map<String, dynamic>?,
      mediaInfo: json['mediaInfo'] as Map<String, dynamic>?,
      languages: json['languages'] as List<dynamic>?,
    );
