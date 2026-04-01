class TautulliMediaItem {
  final String ratingKey;
  final String title;
  final String? year;
  final String mediaType; // movie | episode | track
  final String? thumb;
  final int addedAt; // unix timestamp
  final String? parentTitle;
  final String? grandparentTitle;
  final String? libraryName;
  final int? sectionId;

  const TautulliMediaItem({
    required this.ratingKey,
    required this.title,
    this.year,
    required this.mediaType,
    this.thumb,
    required this.addedAt,
    this.parentTitle,
    this.grandparentTitle,
    this.libraryName,
    this.sectionId,
  });

  factory TautulliMediaItem.fromJson(Map<String, dynamic> json) {
    return TautulliMediaItem(
      ratingKey: json['rating_key']?.toString() ?? '',
      title: json['title'] ?? 'Unknown',
      year: json['year']?.toString(),
      mediaType: json['media_type'] ?? '',
      thumb: json['thumb'],
      addedAt: int.tryParse(json['added_at']?.toString() ?? '0') ?? 0,
      parentTitle: json['parent_title'],
      grandparentTitle: json['grandparent_title'],
      libraryName: json['library_name'],
      sectionId: int.tryParse(json['section_id']?.toString() ?? ''),
    );
  }

  DateTime? get addedAtDate => addedAt > 0
      ? DateTime.fromMillisecondsSinceEpoch(addedAt * 1000)
      : null;

  /// Builds a Tautulli pms_image_proxy URL for the poster.
  String? thumbUrl(String baseUrl, String apiKey) {
    if (thumb == null || thumb!.isEmpty) return null;
    final host = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final base = host.contains('/api/v2') ? host : '$host/api/v2';
    return '$base?cmd=pms_image_proxy&img=${Uri.encodeComponent(thumb!)}&apikey=$apiKey&width=150&height=225';
  }

  /// Display subtitle (e.g. "S01E03" context for episodes).
  String get subtitle {
    if (mediaType == 'episode' && grandparentTitle != null) {
      return grandparentTitle!;
    }
    if (mediaType == 'track' && grandparentTitle != null) {
      return grandparentTitle!;
    }
    return year ?? '';
  }
}
