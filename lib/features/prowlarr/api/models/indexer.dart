class ProwlarrIndexer {
  final int id;
  final String name;
  final bool enable;
  final String protocol; // torrent | usenet
  final String privacy; // public | private | semiPrivate
  final List<String> categories;

  const ProwlarrIndexer({
    required this.id,
    required this.name,
    required this.enable,
    required this.protocol,
    required this.privacy,
    required this.categories,
  });

  factory ProwlarrIndexer.fromJson(Map<String, dynamic> json) {
    final caps = json['capabilities'] as Map<String, dynamic>? ?? {};
    final catList = (caps['categories'] as List? ?? [])
        .map((c) => c['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return ProwlarrIndexer(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      enable: json['enable'] == true,
      protocol: json['protocol'] ?? 'torrent',
      privacy: json['privacy'] ?? 'public',
      categories: catList,
    );
  }
}

class ProwlarrHealthItem {
  final String source;
  final String type; // ok | warning | error
  final String message;

  const ProwlarrHealthItem({
    required this.source,
    required this.type,
    required this.message,
  });

  factory ProwlarrHealthItem.fromJson(Map<String, dynamic> json) {
    return ProwlarrHealthItem(
      source: json['source'] ?? '',
      type: json['type'] ?? 'ok',
      message: json['message'] ?? '',
    );
  }
}
