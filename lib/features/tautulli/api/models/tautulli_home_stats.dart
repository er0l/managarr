class TautulliStatRow {
  final String queryType; // top_movies | top_tv | top_music | top_users
  final String title;
  final int count;
  final String? thumb;
  final String? ratingKey;
  final String? user;
  final int? userId;

  const TautulliStatRow({
    required this.queryType,
    required this.title,
    required this.count,
    this.thumb,
    this.ratingKey,
    this.user,
    this.userId,
  });

  factory TautulliStatRow.fromJson(
      Map<String, dynamic> json, String queryType) {
    // User rows have 'user' instead of 'title'
    final title = json['title'] ??
        json['friendly_name'] ??
        json['user'] ??
        'Unknown';
    return TautulliStatRow(
      queryType: queryType,
      title: title.toString(),
      count: int.tryParse(json['total_plays']?.toString() ?? '0') ?? 0,
      thumb: json['thumb'] ?? json['user_thumb'],
      ratingKey: json['rating_key']?.toString(),
      user: json['user'] ?? json['friendly_name'],
      userId: int.tryParse(json['user_id']?.toString() ?? ''),
    );
  }
}

class TautulliHomeStats {
  final List<TautulliStatRow> topMovies;
  final List<TautulliStatRow> topTv;
  final List<TautulliStatRow> topMusic;
  final List<TautulliStatRow> topUsers;

  const TautulliHomeStats({
    required this.topMovies,
    required this.topTv,
    required this.topMusic,
    required this.topUsers,
  });

  factory TautulliHomeStats.fromJson(List<dynamic> data) {
    List<TautulliStatRow> movies = [];
    List<TautulliStatRow> tv = [];
    List<TautulliStatRow> music = [];
    List<TautulliStatRow> users = [];

    for (final item in data) {
      final statId = item['stat_id']?.toString() ?? '';
      final rows = (item['rows'] as List? ?? [])
          .map((r) =>
              TautulliStatRow.fromJson(r as Map<String, dynamic>, statId))
          .toList();

      if (statId == 'top_movies') {
        movies = rows;
      } else if (statId == 'top_tv') {
        tv = rows;
      } else if (statId == 'top_music') {
        music = rows;
      } else if (statId == 'top_users') {
        users = rows;
      }
    }

    return TautulliHomeStats(
      topMovies: movies,
      topTv: tv,
      topMusic: music,
      topUsers: users,
    );
  }

  bool get isEmpty =>
      topMovies.isEmpty && topTv.isEmpty && topMusic.isEmpty && topUsers.isEmpty;
}
