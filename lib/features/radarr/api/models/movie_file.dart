import 'package:json_annotation/json_annotation.dart';

part 'movie_file.g.dart';

@JsonSerializable(createToJson: false)
class RadarrMovieFile {
  const RadarrMovieFile({
    required this.id,
    this.relativePath,
    this.size,
    this.dateAdded,
    this.quality,
    this.mediaInfo,
    this.languages,
  });

  final int id;
  final String? relativePath;
  @JsonKey(defaultValue: 0)
  final int? size;
  final DateTime? dateAdded;
  final Map<String, dynamic>? quality;
  final Map<String, dynamic>? mediaInfo;
  final List<dynamic>? languages;

  String get qualityName {
    if (quality == null) return 'Unknown';
    final q = quality!['quality'] as Map<String, dynamic>?;
    return q?['name'] as String? ?? 'Unknown';
  }

  String get resolution {
    if (mediaInfo == null) return '';
    return mediaInfo!['resolution'] as String? ?? '';
  }

  String get videoCodec {
    if (mediaInfo == null) return '';
    return mediaInfo!['videoCodec'] as String? ?? '';
  }

  String get audioCodec {
    if (mediaInfo == null) return '';
    return mediaInfo!['audioCodec'] as String? ?? '';
  }

  factory RadarrMovieFile.fromJson(Map<String, dynamic> json) =>
      _$RadarrMovieFileFromJson(json);
}
