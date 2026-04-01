import 'package:json_annotation/json_annotation.dart';

part 'track.g.dart';

@JsonSerializable(explicitToJson: true)
class LidarrTrack {
  const LidarrTrack({
    required this.id,
    required this.title,
    this.trackNumber,
    this.duration,
    this.explicit,
    this.hasFile,
    this.monitored,
    this.artistId,
    this.albumId,
  });

  final int id;
  final String title;
  final String? trackNumber;
  final int? duration;
  final bool? explicit;
  final bool? hasFile;
  final bool? monitored;
  final int? artistId;
  final int? albumId;

  factory LidarrTrack.fromJson(Map<String, dynamic> json) =>
      _$LidarrTrackFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrTrackToJson(this);
}
