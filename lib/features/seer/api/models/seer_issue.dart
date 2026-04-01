class SeerIssue {
  final int id;
  final int issueType;
  final int status;
  final int? problemSeason;
  final int? problemEpisode;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Media info (from nested media object)
  final int tmdbId;
  final String mediaType;

  // Creator
  final String? createdByName;
  final String? createdByAvatar;

  // Comments count
  final int commentCount;

  const SeerIssue({
    required this.id,
    required this.issueType,
    required this.status,
    this.problemSeason,
    this.problemEpisode,
    required this.createdAt,
    required this.updatedAt,
    required this.tmdbId,
    required this.mediaType,
    this.createdByName,
    this.createdByAvatar,
    this.commentCount = 0,
  });

  factory SeerIssue.fromJson(Map<String, dynamic> json) {
    final media = json['media'] as Map<String, dynamic>? ?? {};
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    final comments = json['comments'] as List? ?? [];

    return SeerIssue(
      id: json['id'] as int? ?? 0,
      issueType: json['issueType'] as int? ?? 4,
      status: json['status'] as int? ?? 1,
      problemSeason: json['problemSeason'] as int?,
      problemEpisode: json['problemEpisode'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      tmdbId: media['tmdbId'] as int? ?? 0,
      mediaType: media['mediaType'] as String? ?? 'movie',
      createdByName: createdBy?['displayName'] as String?,
      createdByAvatar: createdBy?['avatar'] as String?,
      commentCount: comments.length,
    );
  }

  bool get isOpen => status == 1;

  String get issueTypeName => switch (issueType) {
        1 => 'Video',
        2 => 'Audio',
        3 => 'Subtitle',
        4 => 'Other',
        _ => 'Unknown',
      };

  String get statusName => isOpen ? 'Open' : 'Resolved';

  String get mediaLabel =>
      mediaType == 'movie' ? 'Movie' : 'TV Show';
}
