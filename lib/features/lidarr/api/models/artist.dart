import 'package:json_annotation/json_annotation.dart';

part 'artist.g.dart';

@JsonSerializable(explicitToJson: true)
class LidarrArtist {
  const LidarrArtist({
    @JsonKey(defaultValue: 0) this.id = 0,
    required this.artistName,
    @JsonKey(defaultValue: false) this.monitored = false,
    this.sortName,
    this.overview,
    this.artistType,
    this.path,
    this.qualityProfileId,
    this.metadataProfileId,
    this.statistics,
    this.images,
    this.added,
    this.foreignArtistId,
    this.tags,
  });

  @JsonKey(defaultValue: 0)
  final int id;
  final String artistName;
  @JsonKey(defaultValue: false)
  final bool monitored;
  final String? sortName;
  final String? overview;
  final String? artistType;
  final String? path;
  final int? qualityProfileId;
  final int? metadataProfileId;
  final LidarrStatistics? statistics;
  final List<LidarrImage>? images;
  final DateTime? added;
  final String? foreignArtistId;
  final List<int>? tags;

  String? get posterUrl => images
      ?.where((i) => i.coverType == 'poster')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  String? get fanartUrl => images
      ?.where((i) => i.coverType == 'fanart')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  factory LidarrArtist.fromJson(Map<String, dynamic> json) =>
      _$LidarrArtistFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrArtistToJson(this);
}

@JsonSerializable()
class LidarrStatistics {
  const LidarrStatistics({
    this.albumCount,
    this.trackCount,
    this.trackFileCount,
    this.sizeOnDisk,
    this.percentOfTracks,
  });

  final int? albumCount;
  final int? trackCount;
  final int? trackFileCount;
  final int? sizeOnDisk;
  final double? percentOfTracks;

  factory LidarrStatistics.fromJson(Map<String, dynamic> json) =>
      _$LidarrStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrStatisticsToJson(this);
}

@JsonSerializable()
class LidarrImage {
  const LidarrImage({required this.coverType, this.remoteUrl});

  final String coverType;
  final String? remoteUrl;

  factory LidarrImage.fromJson(Map<String, dynamic> json) =>
      _$LidarrImageFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrImageToJson(this);
}
