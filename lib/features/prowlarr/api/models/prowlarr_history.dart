class ProwlarrHistoryItem {
  final int id;
  final String indexerName;
  final String title;
  final DateTime date;
  final bool successful;
  final String eventType;
  final String? query;
  final List<String> categories;
  final String? downloadUrl;

  const ProwlarrHistoryItem({
    required this.id,
    required this.indexerName,
    required this.title,
    required this.date,
    required this.successful,
    required this.eventType,
    this.query,
    required this.categories,
    this.downloadUrl,
  });

  factory ProwlarrHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as List? ?? [];
    final cats = rawCats
        .map((c) => (c as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return ProwlarrHistoryItem(
      id: json['id'] ?? 0,
      indexerName: json['indexer'] ?? json['indexerName'] ?? 'Unknown',
      title: json['sourceTitle'] ?? json['title'] ?? 'Unknown',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      successful: json['successful'] as bool? ?? false,
      eventType: json['eventType'] ?? 'unknown',
      query: (json['data'] as Map<String, dynamic>?)?['query'],
      categories: cats,
      downloadUrl: (json['data'] as Map<String, dynamic>?)?['downloadUrl'],
    );
  }
}
