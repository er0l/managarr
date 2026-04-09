class RommRom {
  const RommRom({
    required this.id,
    required this.name,
    required this.fsName,
    required this.fsSizeBytes,
    required this.platformId,
    required this.platformDisplayName,
    this.pathCoverSmall,
    this.pathCoverLarge,
    this.urlCover,
    this.firstReleaseDate,
    this.averageRating,
    this.summary,
    this.genres = const [],
    this.companies = const [],
  });

  final int id;
  final String name;
  final String fsName;
  final int fsSizeBytes;
  final int platformId;
  final String platformDisplayName;
  final String? pathCoverSmall;
  final String? pathCoverLarge;
  final String? urlCover;

  /// Unix timestamp in milliseconds (from ROMM's first_release_date).
  final int? firstReleaseDate;
  final double? averageRating;
  final String? summary;
  final List<String> genres;
  final List<String> companies;

  int? get releaseYear {
    if (firstReleaseDate == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(firstReleaseDate! * 1000).year;
  }

  String get formattedSize {
    if (fsSizeBytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fsSizeBytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
  }

  factory RommRom.fromJson(Map<String, dynamic> json) {
    List<String> toStrings(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    List<String> toNames(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => e['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

    return RommRom(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? json['fs_name'] as String? ?? '',
      fsName: json['fs_name'] as String? ?? '',
      fsSizeBytes: (json['fs_size_bytes'] as num?)?.toInt() ?? 0,
      platformId: (json['platform_id'] as num?)?.toInt() ?? 0,
      platformDisplayName:
          json['platform_display_name'] as String? ?? '',
      pathCoverSmall: json['path_cover_small'] as String?,
      pathCoverLarge: json['path_cover_large'] as String?,
      urlCover: json['url_cover'] as String?,
      firstReleaseDate:
          (json['first_release_date'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      summary: json['summary'] as String?,
      genres: toStrings(json['genres']),
      companies: toNames(json['companies']),
    );
  }
}
