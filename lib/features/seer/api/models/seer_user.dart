class SeerUser {
  final int id;
  final String email;
  final String displayName;
  final String? avatar;
  final int userType; // 1=local, 2=plex
  final int permissions;
  final int requestCount;
  final int movieQuotaLimit;
  final int movieQuotaUsed;
  final int tvQuotaLimit;
  final int tvQuotaUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SeerUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatar,
    required this.userType,
    required this.permissions,
    required this.requestCount,
    required this.movieQuotaLimit,
    required this.movieQuotaUsed,
    required this.tvQuotaLimit,
    required this.tvQuotaUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SeerUser.fromJson(Map<String, dynamic> json) {
    return SeerUser(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      displayName: (json['displayName'] as String?)?.isNotEmpty == true
          ? json['displayName'] as String
          : json['username'] as String? ?? 'Unknown',
      avatar: json['avatar'] as String?,
      userType: json['userType'] as int? ?? 1,
      permissions: json['permissions'] as int? ?? 0,
      requestCount: json['requestCount'] as int? ?? 0,
      movieQuotaLimit: json['movieQuotaLimit'] as int? ?? 0,
      movieQuotaUsed: json['movieQuotaUsed'] as int? ?? 0,
      tvQuotaLimit: json['tvQuotaLimit'] as int? ?? 0,
      tvQuotaUsed: json['tvQuotaUsed'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  bool get isAdmin => permissions & 2 != 0;
  bool get isPlexUser => userType == 2;

  bool get hasMovieQuota => movieQuotaLimit > 0;
  bool get hasTvQuota => tvQuotaLimit > 0;

  double get movieQuotaPercent =>
      hasMovieQuota ? (movieQuotaUsed / movieQuotaLimit).clamp(0.0, 1.0) : 0.0;
  double get tvQuotaPercent =>
      hasTvQuota ? (tvQuotaUsed / tvQuotaLimit).clamp(0.0, 1.0) : 0.0;
}
