class SeerMediaDetail {
  final int id;
  final String mediaType;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final String releaseDate;
  final double voteAverage;
  final int runtime;
  final String status;

  /// Request/availability status from Overseerr mediaInfo (1–5), or null if unknown.
  final int? mediaStatus;

  const SeerMediaDetail({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.runtime,
    required this.status,
    this.mediaStatus,
  });

  factory SeerMediaDetail.fromJson(Map<String, dynamic> json, String type) {
    final episodeRunTimes = json['episodeRunTime'] as List?;
    final runtime = json['runtime'] ??
        (episodeRunTimes != null && episodeRunTimes.isNotEmpty ? episodeRunTimes[0] : 0);
    return SeerMediaDetail(
      id: json['id'] ?? 0,
      mediaType: type,
      title: json['title'] ?? json['name'] ?? 'Unknown',
      overview: json['overview'] ?? '',
      posterPath: json['posterPath'] ?? '',
      backdropPath: json['backdropPath'] ?? '',
      releaseDate: json['releaseDate'] ?? json['firstAirDate'] ?? '',
      voteAverage: (json['voteAverage'] ?? 0).toDouble(),
      runtime: runtime is int ? runtime : 0,
      status: json['status']?.toString() ?? 'Unknown',
      mediaStatus: json['mediaInfo']?['status'] as int?,
    );
  }

  String? get posterUrl {
    if (posterPath.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  String? get backdropUrl {
    if (backdropPath.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/w1280$backdropPath';
  }

  String get year {
    if (releaseDate.length >= 4) return releaseDate.substring(0, 4);
    return '';
  }
}
