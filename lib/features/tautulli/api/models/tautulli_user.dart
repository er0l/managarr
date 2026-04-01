class TautulliUser {
  final int userId;
  final String username;
  final String? friendlyName;
  final String? thumb;
  final int? lastSeen;

  const TautulliUser({
    required this.userId,
    required this.username,
    this.friendlyName,
    this.thumb,
    this.lastSeen,
  });

  factory TautulliUser.fromJson(Map<String, dynamic> json) {
    return TautulliUser(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? 'Unknown',
      friendlyName: json['friendly_name'],
      thumb: json['user_thumb'],
      lastSeen: int.tryParse(json['last_seen']?.toString() ?? '0'),
    );
  }

  DateTime? get lastSeenAt => (lastSeen ?? 0) > 0
      ? DateTime.fromMillisecondsSinceEpoch(lastSeen! * 1000)
      : null;
}
