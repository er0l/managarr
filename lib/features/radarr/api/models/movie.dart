import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

@JsonSerializable(explicitToJson: true)
class RadarrMovie {
  const RadarrMovie({
    this.id = 0,
    required this.title,
    this.year = 0,
    this.monitored = false,
    this.hasFile = false,
    this.tmdbId,
    this.sortTitle,
    this.added,
    this.studio,
    this.overview,
    this.runtime,
    this.sizeOnDisk,
    this.certification,
    this.inCinemas,
    this.physicalRelease,
    this.digitalRelease,
    this.status,
    this.qualityProfileId,
    this.minimumAvailability,
    this.rootFolderPath,
    this.path,
    this.tags,
    this.images,
    this.qualityName,
  });

  @JsonKey(defaultValue: 0)
  final int id;
  final String title;
  @JsonKey(defaultValue: 0)
  final int year;
  @JsonKey(defaultValue: false)
  final bool monitored;
  @JsonKey(defaultValue: false)
  final bool hasFile;
  final int? tmdbId;
  final String? sortTitle;
  final DateTime? added;
  final String? studio;
  final String? overview;
  final int? runtime;
  final int? sizeOnDisk;
  final String? certification;
  final DateTime? inCinemas;
  final DateTime? physicalRelease;
  final DateTime? digitalRelease;

  /// e.g. 'released', 'announced', 'inCinemas'
  final String? status;
  final int? qualityProfileId;

  /// e.g. 'announced', 'inCinemas', 'released'
  final String? minimumAvailability;
  final String? rootFolderPath;
  final String? path;
  final List<int>? tags;

  final List<RadarrImage>? images;

  /// Quality name from the downloaded movie file, e.g. "Bluray-1080p".
  final String? qualityName;

  String? get posterUrl => images
      ?.where((i) => i.coverType == 'poster')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  String? get fanartUrl => images
      ?.where((i) => i.coverType == 'fanart')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  factory RadarrMovie.fromJson(Map<String, dynamic> json) =>
      _$RadarrMovieFromJson(json);

  Map<String, dynamic> toJson() => _$RadarrMovieToJson(this);
}

@JsonSerializable()
class RadarrImage {
  const RadarrImage({required this.coverType, this.remoteUrl});

  final String coverType;
  final String? remoteUrl;

  factory RadarrImage.fromJson(Map<String, dynamic> json) =>
      _$RadarrImageFromJson(json);

  Map<String, dynamic> toJson() => _$RadarrImageToJson(this);
}
