class TautulliHistoryItem {
  final int referenceId;
  final String? user;
  final String? friendlyName;
  final String? title;
  final String? parentTitle;
  final String? grandparentTitle;
  final String? mediaType;
  final int stopped; // unix timestamp
  final int duration; // seconds
  final int percentComplete;
  final String? thumb;

  const TautulliHistoryItem({
    required this.referenceId,
    this.user,
    this.friendlyName,
    this.title,
    this.parentTitle,
    this.grandparentTitle,
    this.mediaType,
    required this.stopped,
    required this.duration,
    required this.percentComplete,
    this.thumb,
  });

  factory TautulliHistoryItem.fromJson(Map<String, dynamic> json) {
    return TautulliHistoryItem(
      referenceId: json['reference_id'] ?? 0,
      user: json['user'],
      friendlyName: json['friendly_name'],
      title: json['title'],
      parentTitle: json['parent_title'],
      grandparentTitle: json['grandparent_title'],
      mediaType: json['media_type'],
      stopped: json['stopped'] ?? 0,
      duration: json['duration'] ?? 0,
      percentComplete: json['percent_complete'] ?? 0,
      thumb: json['thumb'],
    );
  }

  DateTime? get stoppedAt => stopped > 0
      ? DateTime.fromMillisecondsSinceEpoch(stopped * 1000)
      : null;
}

class TautulliHistory {
  final List<TautulliHistoryItem> items;

  const TautulliHistory({required this.items});

  factory TautulliHistory.fromJson(Map<String, dynamic> json) {
    return TautulliHistory(
      items: (json['data'] as List? ?? [])
          .map((h) => TautulliHistoryItem.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}
