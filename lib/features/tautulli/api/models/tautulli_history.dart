int tautulliInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

class TautulliHistoryItem {
  const TautulliHistoryItem({
    required this.referenceId,
    this.rowId = 0,
    this.userId = 0,
    this.ratingKey = '',
    this.parentRatingKey = '',
    this.grandparentRatingKey = '',
    this.user,
    this.friendlyName,
    this.title,
    this.parentTitle,
    this.grandparentTitle,
    this.mediaType,
    required this.stopped,
    this.started = 0,
    required this.duration,
    required this.percentComplete,
    this.thumb,
    this.art,
    this.parentThumb,
    this.grandparentThumb,
    this.season = 0,
    this.episode = 0,
    this.year = 0,
    this.player,
    this.platform,
    this.ipAddress,
    this.transcodeDecision,
    this.quality,
    this.raw = const {},
  });
  final int referenceId,
      rowId,
      userId,
      stopped,
      started,
      duration,
      percentComplete,
      season,
      episode,
      year;
  final String ratingKey, parentRatingKey, grandparentRatingKey;
  final String? user,
      friendlyName,
      title,
      parentTitle,
      grandparentTitle,
      mediaType,
      thumb,
      art,
      parentThumb,
      grandparentThumb,
      player,
      platform,
      ipAddress,
      transcodeDecision,
      quality;
  final Map<String, dynamic> raw;

  factory TautulliHistoryItem.fromJson(Map<String, dynamic> json) =>
      TautulliHistoryItem(
        referenceId: tautulliInt(json['reference_id']),
        rowId: tautulliInt(json['row_id'] ?? json['id']),
        userId: tautulliInt(json['user_id']),
        ratingKey: json['rating_key']?.toString() ?? '',
        parentRatingKey: json['parent_rating_key']?.toString() ?? '',
        grandparentRatingKey: json['grandparent_rating_key']?.toString() ?? '',
        user: json['user']?.toString(),
        friendlyName: json['friendly_name']?.toString(),
        title: json['title']?.toString(),
        parentTitle: json['parent_title']?.toString(),
        grandparentTitle: json['grandparent_title']?.toString(),
        mediaType: json['media_type']?.toString(),
        stopped: tautulliInt(json['stopped']),
        started: tautulliInt(json['started'] ?? json['date']),
        duration: tautulliInt(json['duration']),
        percentComplete: tautulliInt(json['percent_complete']).clamp(0, 100),
        thumb: json['thumb']?.toString(),
        art: json['art']?.toString(),
        parentThumb: json['parent_thumb']?.toString(),
        grandparentThumb: json['grandparent_thumb']?.toString(),
        season: tautulliInt(json['parent_media_index']),
        episode: tautulliInt(json['media_index']),
        year: tautulliInt(json['year']),
        player: json['player']?.toString(),
        platform: json['platform']?.toString(),
        ipAddress: json['ip_address']?.toString(),
        transcodeDecision: json['transcode_decision']?.toString(),
        quality: json['quality_profile']?.toString(),
        raw: Map.unmodifiable(json),
      );

  DateTime? get stoppedAt =>
      stopped > 0 ? DateTime.fromMillisecondsSinceEpoch(stopped * 1000) : null;
  DateTime? get startedAt =>
      started > 0 ? DateTime.fromMillisecondsSinceEpoch(started * 1000) : null;
  String get displayTitle => (grandparentTitle?.isNotEmpty == true)
      ? grandparentTitle!
      : title ?? 'Unknown';
  String get subtitle => mediaType == 'episode'
      ? '${season > 0 ? 'S${season.toString().padLeft(2, '0')}' : 'Specials'}E${episode.toString().padLeft(2, '0')} · ${title ?? ''}'
      : mediaType == 'track'
      ? [parentTitle, title].whereType<String>().join(' · ')
      : year > 0
      ? '$year'
      : mediaType ?? '';
  String? get poster =>
      (mediaType == 'episode'
              ? [grandparentThumb, parentThumb, thumb]
              : [thumb])
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .firstOrNull;
  String? get background => art?.isNotEmpty == true
      ? art
      : grandparentRatingKey.isNotEmpty
      ? '/library/metadata/$grandparentRatingKey/art'
      : ratingKey.isNotEmpty
      ? '/library/metadata/$ratingKey/art'
      : null;
}

class TautulliHistory {
  const TautulliHistory({required this.items, this.totalRecords = 0});
  final List<TautulliHistoryItem> items;
  final int totalRecords;
  factory TautulliHistory.fromJson(
    Map<String, dynamic> json,
  ) => TautulliHistory(
    items: (json['data'] as List? ?? [])
        .map(
          (h) =>
              TautulliHistoryItem.fromJson(Map<String, dynamic>.from(h as Map)),
        )
        .toList(),
    totalRecords: tautulliInt(json['recordsFiltered'] ?? json['recordsTotal']),
  );
}
