class TautulliSession {
  final String? sessionKey;
  final String? user;
  final String? friendlyName;
  final String? title;
  final String? parentTitle;
  final String? grandparentTitle;
  final String? mediaType;
  final int progressPercent;
  final String? state; // playing, paused, buffering
  final String? player;
  final String? product;
  final String? thumb;

  // Detail fields
  final String? videoResolution;
  final String? videoCodec;
  final String? audioCodec;
  final String? container;
  final String? transcodeDecision; // direct play | transcode | copy
  final int streamBitrate; // kbps
  final int videoBitrate; // kbps
  final String? ipAddress;
  final String? location; // lan | wan
  final String? ratingKey;
  final int duration; // ms
  final int viewOffset; // ms
  final String? qualityProfile;

  const TautulliSession({
    this.sessionKey,
    this.user,
    this.friendlyName,
    this.title,
    this.parentTitle,
    this.grandparentTitle,
    this.mediaType,
    required this.progressPercent,
    this.state,
    this.player,
    this.product,
    this.thumb,
    this.videoResolution,
    this.videoCodec,
    this.audioCodec,
    this.container,
    this.transcodeDecision,
    this.streamBitrate = 0,
    this.videoBitrate = 0,
    this.ipAddress,
    this.location,
    this.ratingKey,
    this.duration = 0,
    this.viewOffset = 0,
    this.qualityProfile,
  });

  factory TautulliSession.fromJson(Map<String, dynamic> json) {
    return TautulliSession(
      sessionKey: json['session_key']?.toString(),
      user: json['user'],
      friendlyName: json['friendly_name'],
      title: json['title'],
      parentTitle: json['parent_title'],
      grandparentTitle: json['grandparent_title'],
      mediaType: json['media_type'],
      progressPercent:
          int.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0,
      state: json['state'],
      player: json['player'],
      product: json['product'],
      thumb: json['thumb'],
      videoResolution: json['video_resolution'],
      videoCodec: json['video_codec'],
      audioCodec: json['audio_codec'],
      container: json['container'],
      transcodeDecision: json['transcode_decision'],
      streamBitrate:
          int.tryParse(json['stream_bitrate']?.toString() ?? '0') ?? 0,
      videoBitrate:
          int.tryParse(json['video_bitrate']?.toString() ?? '0') ?? 0,
      ipAddress: json['ip_address'],
      location: json['location'],
      ratingKey: json['rating_key']?.toString(),
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      viewOffset: int.tryParse(json['view_offset']?.toString() ?? '0') ?? 0,
      qualityProfile: json['quality_profile'],
    );
  }

  String get displayTitle => title ?? 'Unknown';

  static String _fmt(int ms) {
    final s = ms ~/ 1000;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String get durationFormatted => _fmt(duration);
  String get viewOffsetFormatted => _fmt(viewOffset);

  double get progressFraction {
    if (duration <= 0) return progressPercent / 100;
    return (viewOffset / duration).clamp(0.0, 1.0);
  }
}

class TautulliActivity {
  final int streamCount;
  final List<TautulliSession> sessions;

  const TautulliActivity({
    required this.streamCount,
    required this.sessions,
  });

  factory TautulliActivity.fromJson(Map<String, dynamic> json) {
    return TautulliActivity(
      streamCount:
          int.tryParse(json['stream_count']?.toString() ?? '0') ?? 0,
      sessions: (json['sessions'] as List? ?? [])
          .map((s) => TautulliSession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
