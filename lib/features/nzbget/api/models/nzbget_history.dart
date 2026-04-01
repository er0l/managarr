class NzbgetHistoryItem {
  final int id;
  final String name;
  final String status;
  final int historyTime;
  final int fileSizeHigh;
  final int fileSizeLow;
  final String category;
  final String destDir;
  final int downloadTimeSec;
  final int health;

  const NzbgetHistoryItem({
    required this.id,
    required this.name,
    required this.status,
    required this.historyTime,
    required this.fileSizeHigh,
    required this.fileSizeLow,
    required this.category,
    required this.destDir,
    required this.downloadTimeSec,
    required this.health,
  });

  factory NzbgetHistoryItem.fromJson(Map<String, dynamic> json) {
    return NzbgetHistoryItem(
      id: json['NZBID'] ?? -1,
      name: json['Name'] ?? 'Unknown',
      status: json['Status'] ?? 'Unknown',
      historyTime: json['HistoryTime'] ?? 0,
      fileSizeHigh: json['FileSizeHi'] ?? 0,
      fileSizeLow: json['FileSizeLo'] ?? 0,
      category: json['Category'] ?? 'Unknown',
      destDir: json['DestDir'] ?? 'Unknown',
      downloadTimeSec: json['DownloadTimeSec'] ?? 0,
      health: json['Health'] ?? 0,
    );
  }

  int get fileSize => (fileSizeHigh << 32) + fileSizeLow;

  DateTime? get completedAt => historyTime > 0
      ? DateTime.fromMillisecondsSinceEpoch(historyTime * 1000)
      : null;
}

class NzbgetHistory {
  final List<NzbgetHistoryItem> items;

  const NzbgetHistory({required this.items});

  factory NzbgetHistory.fromJson(List<dynamic> json) {
    return NzbgetHistory(
      items: json
          .map((item) => NzbgetHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
