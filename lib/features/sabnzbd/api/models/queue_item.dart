class SabnzbdQueueItem {
  final String nzoId;
  final String filename;
  final String status; // Downloading, Paused, Queued, etc.
  final double percentage;
  final String size;
  final String sizeLeft;
  final String timeLeft;
  final String category;
  final int priority;

  const SabnzbdQueueItem({
    required this.nzoId,
    required this.filename,
    required this.status,
    required this.percentage,
    required this.size,
    required this.sizeLeft,
    required this.timeLeft,
    required this.category,
    required this.priority,
  });

  factory SabnzbdQueueItem.fromJson(Map<String, dynamic> json) {
    return SabnzbdQueueItem(
      nzoId: json['nzo_id'] ?? '',
      filename: json['filename'] ?? json['name'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
      size: json['size'] ?? '0 B',
      sizeLeft: json['sizeleft'] ?? '0 B',
      timeLeft: json['timeleft'] ?? '0:00:00',
      category: json['cat'] ?? '*',
      priority: int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isDownloading => status == 'Downloading';
  bool get isPaused => status == 'Paused';
}

class SabnzbdQueue {
  final bool paused;
  final String speed;
  final String sizeLeft;
  final String timeLeft;
  final List<SabnzbdQueueItem> items;

  const SabnzbdQueue({
    required this.paused,
    required this.speed,
    required this.sizeLeft,
    required this.timeLeft,
    required this.items,
  });

  factory SabnzbdQueue.fromJson(Map<String, dynamic> json) {
    final q = json['queue'] as Map<String, dynamic>? ?? {};
    final slots = (q['slots'] as List? ?? [])
        .map((j) => SabnzbdQueueItem.fromJson(j as Map<String, dynamic>))
        .toList();
    return SabnzbdQueue(
      paused: q['paused'] == true,
      speed: q['speed'] ?? '0',
      sizeLeft: q['sizeleft'] ?? '0 B',
      timeLeft: q['timeleft'] ?? '0:00:00',
      items: slots,
    );
  }
}
