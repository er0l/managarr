class TautulliLogEntry {
  final String timestamp;
  final String level; // DEBUG | INFO | WARNING | ERROR
  final String thread;
  final String message;

  const TautulliLogEntry({
    required this.timestamp,
    required this.level,
    required this.thread,
    required this.message,
  });

  factory TautulliLogEntry.fromJson(Map<String, dynamic> json) {
    return TautulliLogEntry(
      timestamp: json['timestamp']?.toString() ?? '',
      level: json['level']?.toString().toUpperCase() ?? 'INFO',
      thread: json['thread']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
