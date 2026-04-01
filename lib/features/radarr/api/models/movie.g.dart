// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarrMovie _$RadarrMovieFromJson(Map<String, dynamic> json) => RadarrMovie(
  id: (json['id'] as num?)?.toInt() ?? 0,
  title: json['title'] as String,
  year: (json['year'] as num?)?.toInt() ?? 0,
  monitored: json['monitored'] as bool? ?? false,
  hasFile: json['hasFile'] as bool? ?? false,
  tmdbId: (json['tmdbId'] as num?)?.toInt(),
  sortTitle: json['sortTitle'] as String?,
  added: json['added'] == null ? null : DateTime.parse(json['added'] as String),
  studio: json['studio'] as String?,
  overview: json['overview'] as String?,
  runtime: (json['runtime'] as num?)?.toInt(),
  sizeOnDisk: (json['sizeOnDisk'] as num?)?.toInt(),
  certification: json['certification'] as String?,
  inCinemas: json['inCinemas'] == null
      ? null
      : DateTime.parse(json['inCinemas'] as String),
  physicalRelease: json['physicalRelease'] == null
      ? null
      : DateTime.parse(json['physicalRelease'] as String),
  digitalRelease: json['digitalRelease'] == null
      ? null
      : DateTime.parse(json['digitalRelease'] as String),
  status: json['status'] as String?,
  qualityProfileId: (json['qualityProfileId'] as num?)?.toInt(),
  minimumAvailability: json['minimumAvailability'] as String?,
  rootFolderPath: json['rootFolderPath'] as String?,
  path: json['path'] as String?,
  tags: (json['tags'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => RadarrImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  qualityName: (((json['movieFile'] as Map<String, dynamic>?)?['quality']
        as Map<String, dynamic>?)?['quality']
        as Map<String, dynamic>?)?['name'] as String?,
);

Map<String, dynamic> _$RadarrMovieToJson(RadarrMovie instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'year': instance.year,
      'monitored': instance.monitored,
      'hasFile': instance.hasFile,
      'tmdbId': instance.tmdbId,
      'sortTitle': instance.sortTitle,
      'added': instance.added?.toIso8601String(),
      'studio': instance.studio,
      'overview': instance.overview,
      'runtime': instance.runtime,
      'sizeOnDisk': instance.sizeOnDisk,
      'certification': instance.certification,
      'inCinemas': instance.inCinemas?.toIso8601String(),
      'physicalRelease': instance.physicalRelease?.toIso8601String(),
      'digitalRelease': instance.digitalRelease?.toIso8601String(),
      'status': instance.status,
      'qualityProfileId': instance.qualityProfileId,
      'minimumAvailability': instance.minimumAvailability,
      'rootFolderPath': instance.rootFolderPath,
      'path': instance.path,
      'tags': instance.tags,
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'qualityName': instance.qualityName,
    };

RadarrImage _$RadarrImageFromJson(Map<String, dynamic> json) => RadarrImage(
  coverType: json['coverType'] as String,
  remoteUrl: json['remoteUrl'] as String?,
);

Map<String, dynamic> _$RadarrImageToJson(RadarrImage instance) =>
    <String, dynamic>{
      'coverType': instance.coverType,
      'remoteUrl': instance.remoteUrl,
    };
