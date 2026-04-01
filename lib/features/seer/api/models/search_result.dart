class SeerSearchResult {
  final int id;
  final String mediaType; // movie | tv
  final String title;
  final String overview;
  final String posterPath;
  final String releaseDate;
  final double voteAverage;

  const SeerSearchResult({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  factory SeerSearchResult.fromJson(Map<String, dynamic> json) {
    return SeerSearchResult(
      id: json['id'] ?? 0,
      mediaType: json['mediaType'] ?? '',
      title: json['title'] ?? json['name'] ?? 'Unknown',
      overview: json['overview'] ?? '',
      posterPath: json['posterPath'] ?? '',
      releaseDate: json['releaseDate'] ?? json['firstAirDate'] ?? '',
      voteAverage: (json['voteAverage'] ?? 0).toDouble(),
    );
  }

  /// Full TMDB poster URL (w500 size).
  String? get posterUrl {
    if (posterPath.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  String get year {
    if (releaseDate.length >= 4) return releaseDate.substring(0, 4);
    return '';
  }
}
