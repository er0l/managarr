import 'package:json_annotation/json_annotation.dart';

part 'album.g.dart';

@JsonSerializable(explicitToJson: true)
class LidarrAlbum {
  const LidarrAlbum({
    required this.id,
    required this.title,
    required this.monitored,
    this.artistId,
    this.releaseDate,
    this.statistics,
    this.images,
  });

  final int id;
  final String title;
  final bool monitored;
  final int? artistId;
  final DateTime? releaseDate;
  final LidarrAlbumStatistics? statistics;
  final List<LidarrAlbumImage>? images;

  String? get coverUrl => images
      ?.where((i) => i.coverType == 'cover')
      .map((i) => i.remoteUrl)
      .firstOrNull;

  factory LidarrAlbum.fromJson(Map<String, dynamic> json) =>
      _$LidarrAlbumFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrAlbumToJson(this);
}

@JsonSerializable()
class LidarrAlbumStatistics {
  const LidarrAlbumStatistics({
    this.trackCount,
    this.trackFileCount,
    this.sizeOnDisk,
    this.percentOfTracks,
  });

  final int? trackCount;
  final int? trackFileCount;
  final int? sizeOnDisk;
  final double? percentOfTracks;

  factory LidarrAlbumStatistics.fromJson(Map<String, dynamic> json) =>
      _$LidarrAlbumStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrAlbumStatisticsToJson(this);
}

@JsonSerializable()
class LidarrAlbumImage {
  const LidarrAlbumImage({required this.coverType, this.remoteUrl});

  final String coverType;
  final String? remoteUrl;

  factory LidarrAlbumImage.fromJson(Map<String, dynamic> json) =>
      _$LidarrAlbumImageFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrAlbumImageToJson(this);
}
