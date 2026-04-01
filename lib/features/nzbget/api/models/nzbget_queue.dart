class NzbgetQueueItem {
  final int id;
  final String name;
  final String status;
  final int remainingSizeHigh;
  final int remainingSizeLow;
  final int fileSizeHigh;
  final int fileSizeLow;
  final String category;

  const NzbgetQueueItem({
    required this.id,
    required this.name,
    required this.status,
    required this.remainingSizeHigh,
    required this.remainingSizeLow,
    required this.fileSizeHigh,
    required this.fileSizeLow,
    required this.category,
  });

  factory NzbgetQueueItem.fromJson(Map<String, dynamic> json) {
    return NzbgetQueueItem(
      id: json['NZBID'] ?? -1,
      name: json['NZBName'] ?? 'Unknown',
      status: json['Status'] ?? 'UNKNOWN',
      remainingSizeHigh: json['RemainingSizeHi'] ?? 0,
      remainingSizeLow: json['RemainingSizeLo'] ?? 0,
      fileSizeHigh: json['FileSizeHi'] ?? 0,
      fileSizeLow: json['FileSizeLo'] ?? 0,
      category: json['Category'] ?? '',
    );
  }

  int get remainingSize => (remainingSizeHigh << 32) + remainingSizeLow;
  int get fileSize => (fileSizeHigh << 32) + fileSizeLow;
}

class NzbgetQueue {
  final List<NzbgetQueueItem> items;

  const NzbgetQueue({required this.items});

  factory NzbgetQueue.fromJson(List<dynamic> json) {
    return NzbgetQueue(
      items: json
          .map((item) => NzbgetQueueItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
