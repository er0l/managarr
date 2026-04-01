class TautulliUserDetail {
  final int userId;
  final String username;
  final String? friendlyName;
  final String? thumb;
  final int totalPlays;
  final int totalTime; // seconds
  final int? lastSeen; // unix timestamp
  final String? lastPlayed;

  const TautulliUserDetail({
    required this.userId,
    required this.username,
    this.friendlyName,
    this.thumb,
    required this.totalPlays,
    required this.totalTime,
    this.lastSeen,
    this.lastPlayed,
  });

  /// Combine responses from get_user and get_user_watch_time_stats.
  factory TautulliUserDetail.fromJson({
    required Map<String, dynamic> userJson,
    required List<dynamic> watchTimeJson,
  }) {
    int totalPlays = 0;
    int totalTime = 0;

    // watch_time_stats returns a list of time-range rows; sum them or use "all time"
    for (final row in watchTimeJson) {
      final queryDays = int.tryParse(row['query_days']?.toString() ?? '0') ?? 0;
      if (queryDays == 0) {
        // "All time" row
        totalPlays = int.tryParse(row['total_plays']?.toString() ?? '0') ?? 0;
        totalTime = int.tryParse(row['total_time']?.toString() ?? '0') ?? 0;
        break;
      }
    }

    return TautulliUserDetail(
      userId: int.tryParse(userJson['user_id']?.toString() ?? '0') ?? 0,
      username: userJson['username'] ?? 'Unknown',
      friendlyName: userJson['friendly_name'],
      thumb: userJson['user_thumb'],
      totalPlays: totalPlays,
      totalTime: totalTime,
      lastSeen: int.tryParse(userJson['last_seen']?.toString() ?? ''),
      lastPlayed: userJson['last_played'],
    );
  }

  String get displayName => friendlyName ?? username;

  DateTime? get lastSeenAt => (lastSeen ?? 0) > 0
      ? DateTime.fromMillisecondsSinceEpoch(lastSeen! * 1000)
      : null;

  /// Format total watch time as "Xh Ym"
  String get totalTimeFormatted {
    final h = totalTime ~/ 3600;
    final m = (totalTime % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
