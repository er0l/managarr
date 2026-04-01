class ProwlarrSearchResult {
  final String guid;
  final String indexerName;
  final String title;
  final int size; // bytes
  final DateTime? publishDate;
  final String? downloadUrl;
  final String protocol; // torrent | usenet
  final int? seeders;
  final int? leechers;
  final List<String> categories;
  final int indexerId;

  const ProwlarrSearchResult({
    required this.guid,
    required this.indexerName,
    required this.title,
    required this.size,
    this.publishDate,
    this.downloadUrl,
    required this.protocol,
    this.seeders,
    this.leechers,
    required this.categories,
    required this.indexerId,
  });

  factory ProwlarrSearchResult.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as List? ?? [];
    final cats = rawCats
        .map((c) => (c as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return ProwlarrSearchResult(
      guid: json['guid']?.toString() ?? '',
      indexerName: json['indexer'] ?? 'Unknown',
      title: json['title'] ?? 'Unknown',
      size: (json['size'] as num?)?.toInt() ?? 0,
      publishDate: DateTime.tryParse(json['publishDate']?.toString() ?? ''),
      downloadUrl: json['downloadUrl'],
      protocol: json['protocol'] ?? 'torrent',
      seeders: json['seeders'] as int?,
      leechers: json['leechers'] as int?,
      categories: cats,
      indexerId: json['indexerId'] ?? 0,
    );
  }

  String get sizeFormatted {
    if (size <= 0) return '—';
    if (size >= 1073741824) {
      return '${(size / 1073741824).toStringAsFixed(1)} GB';
    }
    if (size >= 1048576) {
      return '${(size / 1048576).toStringAsFixed(0)} MB';
    }
    return '${(size / 1024).toStringAsFixed(0)} KB';
  }

  String get ageFormatted {
    if (publishDate == null) return '—';
    final days = DateTime.now().difference(publishDate!).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return '1d';
    if (days < 30) return '${days}d';
    final months = (days / 30).floor();
    if (months < 12) return '${months}mo';
    return '${(months / 12).floor()}y';
  }
}
