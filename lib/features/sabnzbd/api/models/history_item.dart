class SabnzbdHistoryItem {
  final String nzoId;
  final String name;
  final String status; // Completed, Failed, etc.
  final String size;
  final String category;
  final int completedAt; // unix timestamp

  const SabnzbdHistoryItem({
    required this.nzoId,
    required this.name,
    required this.status,
    required this.size,
    required this.category,
    required this.completedAt,
  });

  factory SabnzbdHistoryItem.fromJson(Map<String, dynamic> json) {
    return SabnzbdHistoryItem(
      nzoId: json['nzo_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      size: json['size'] ?? '0 B',
      category: json['category'] ?? '*',
      completedAt: json['completed'] ?? 0,
    );
  }

  bool get isCompleted => status == 'Completed';
  bool get isFailed => status == 'Failed';

  DateTime? get completedDateTime => completedAt > 0
      ? DateTime.fromMillisecondsSinceEpoch(completedAt * 1000)
      : null;
}
