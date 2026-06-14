class TautulliSession {
  final String? sessionKey;
  final String? user;
  final String? friendlyName;
  final String? title;
  final String? parentTitle;
  final String? grandparentTitle;
  final String? mediaType;
  final int progressPercent;
  final String? state;
  final String? player;
  final String? product;
  final String? thumb;
  final String? platform; // e.g. "Android (12)"
  final int? userId;
  final int? sectionId;

  // Metadata
  final int? year;
  final String? libraryName;

  // Stream detail
  final String? videoResolution;
  final String? videoCodec;
  final String? audioCodec;
  final String? audioChannelLayout; // e.g. "5.1"
  final String? audioLanguage;
  final String? container;
  final String? transcodeDecision;
  final int streamBitrate; // kbps
  final int videoBitrate; // kbps
  final String? subtitleCodec;
  final String? subtitleLanguage;
  final bool subtitlesOn;

  // Stream vs source decision strings (from stream_* fields)
  final String? streamVideoDecision;
  final String? streamAudioDecision;
  final String? streamSubtitleDecision;
  final String? streamContainerDecision;

  final String? ipAddress;
  final String? location;
  final String? ratingKey;
  final int duration;
  final int viewOffset;
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
    this.platform,
    this.userId,
    this.sectionId,
    this.year,
    this.libraryName,
    this.videoResolution,
    this.videoCodec,
    this.audioCodec,
    this.audioChannelLayout,
    this.audioLanguage,
    this.container,
    this.transcodeDecision,
    this.streamBitrate = 0,
    this.videoBitrate = 0,
    this.subtitleCodec,
    this.subtitleLanguage,
    this.subtitlesOn = false,
    this.streamVideoDecision,
    this.streamAudioDecision,
    this.streamSubtitleDecision,
    this.streamContainerDecision,
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
      platform: json['platform'],
      userId: int.tryParse(json['user_id']?.toString() ?? ''),
      sectionId: int.tryParse(json['library_id']?.toString() ?? '') ??
          int.tryParse(json['section_id']?.toString() ?? ''),
      year: int.tryParse(json['year']?.toString() ?? ''),
      libraryName: json['library_name'],
      videoResolution: json['video_resolution'],
      videoCodec: json['video_codec'],
      audioCodec: json['audio_codec'],
      audioChannelLayout: json['audio_channel_layout'],
      audioLanguage: json['audio_language'],
      container: json['container'],
      transcodeDecision: json['transcode_decision'],
      streamBitrate:
          int.tryParse(json['stream_bitrate']?.toString() ?? '0') ?? 0,
      videoBitrate:
          int.tryParse(json['video_bitrate']?.toString() ?? '0') ?? 0,
      subtitleCodec: json['subtitle_codec'],
      subtitleLanguage: json['subtitle_language'],
      subtitlesOn: (json['subtitles'] == 1 || json['subtitles'] == true),
      streamVideoDecision: json['stream_video_decision'],
      streamAudioDecision: json['stream_audio_decision'],
      streamSubtitleDecision: json['stream_subtitle_decision'],
      streamContainerDecision: json['stream_container_decision'],
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

  // ETA: time when playback will finish
  DateTime? get eta {
    if (duration <= 0 || viewOffset >= duration) return null;
    final remainingMs = duration - viewOffset;
    return DateTime.now().add(Duration(milliseconds: remainingMs));
  }

  // Format "00:00 / 01:36:51 (46%)"
  String get progressFormatted =>
      '$viewOffsetFormatted / $durationFormatted ($progressPercent%)';

  // Build human-readable stream decision label
  static String _decisionLabel(String? decision) {
    final d = decision?.toLowerCase() ?? '';
    if (d.contains('direct')) return 'Direct Play';
    if (d == 'copy') return 'Direct Stream';
    if (d == 'transcode') return 'Transcode';
    return decision ?? '—';
  }

  String get streamDecisionLabel => _decisionLabel(transcodeDecision);

  String get videoStreamLabel {
    final dec = _decisionLabel(streamVideoDecision ?? transcodeDecision);
    final parts = [
      if (videoCodec?.isNotEmpty == true) videoCodec!.toUpperCase(),
      if (videoResolution?.isNotEmpty == true) videoResolution!,
    ].join(' ');
    return parts.isNotEmpty ? '$dec ($parts)' : dec;
  }

  String get audioStreamLabel {
    final dec = _decisionLabel(streamAudioDecision ?? transcodeDecision);
    final lang = (audioLanguage?.isNotEmpty == true) ? audioLanguage! : null;
    final codec = (audioCodec?.isNotEmpty == true) ? audioCodec!.toUpperCase() : null;
    final ch = (audioChannelLayout?.isNotEmpty == true) ? audioChannelLayout! : null;
    final codecPart = (codec != null || ch != null)
        ? [codec, ch].whereType<String>().join(' ')
        : null;
    final parts = [lang, codecPart].whereType<String>().join(' - ');
    return parts.isNotEmpty ? '$dec ($parts)' : dec;
  }

  String get subtitleStreamLabel {
    if (!subtitlesOn) return 'None';
    final dec = _decisionLabel(streamSubtitleDecision ?? transcodeDecision);
    final lang = (subtitleLanguage?.isNotEmpty == true) ? subtitleLanguage! : null;
    final codec = (subtitleCodec?.isNotEmpty == true) ? subtitleCodec!.toUpperCase() : null;
    final parts = [lang, codec].whereType<String>().join(' - ');
    return parts.isNotEmpty ? '$dec ($parts)' : dec;
  }

  String get containerStreamLabel {
    final dec = _decisionLabel(streamContainerDecision ?? transcodeDecision);
    final cont = container?.toUpperCase() ?? '';
    return cont.isNotEmpty ? '$dec ($cont)' : dec;
  }

  String get bandwidthLabel =>
      streamBitrate > 0 ? '${(streamBitrate / 1000).toStringAsFixed(1)} Mbps' : '—';
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
