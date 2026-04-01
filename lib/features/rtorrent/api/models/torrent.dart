class RTorrentTorrent {
  final String hash;
  final String name;
  final int size;
  final int completed;
  final int downRate;
  final int upRate;
  final bool isActive;
  final int state;
  final String message;
  final int dateAdded;
  final int dateDone;
  final double ratio;
  final String label;

  const RTorrentTorrent({
    required this.hash,
    required this.name,
    required this.size,
    required this.completed,
    required this.downRate,
    required this.upRate,
    required this.isActive,
    required this.state,
    required this.message,
    required this.dateAdded,
    required this.dateDone,
    required this.ratio,
    required this.label,
  });

  int get percentageDone =>
      size == 0 ? 0 : ((completed / size) * 100).clamp(0, 100).round();

  bool get isCompleted => completed >= size;
  bool get isSeeding => isCompleted && isActive;
  bool get isFinished => isCompleted && !isActive;
  bool get isDownloading => !isCompleted && isActive;
  bool get isError => message.isNotEmpty;
  bool get isPaused => !isCompleted && !isActive && state == 1;
  bool get isStopped => state == 0;

  String get statusLabel {
    if (isError) return 'Error';
    if (isSeeding) return 'Seeding';
    if (isFinished) return 'Finished';
    if (isDownloading) return 'Downloading';
    if (isPaused) return 'Paused';
    return 'Stopped';
  }
}

class RTorrentTracker {
  final String url;
  final int type;

  const RTorrentTracker({required this.url, required this.type});
}

class RTorrentFile {
  final String path;
  final int size;
  final int completedChunks;
  final int sizeChunks;

  const RTorrentFile({
    required this.path,
    required this.size,
    required this.completedChunks,
    required this.sizeChunks,
  });

  int get percentageDone =>
      sizeChunks == 0 ? 0 : ((completedChunks / sizeChunks) * 100).clamp(0, 100).round();

  bool get isCompleted => completedChunks >= sizeChunks && sizeChunks > 0;
}
