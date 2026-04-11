class RommStats {
  const RommStats({
    this.totalRoms = 0,
    this.totalPlatforms = 0,
    this.totalCollections = 0,
    this.totalSizeBytes = 0,
  });

  final int totalRoms;
  final int totalPlatforms;
  final int totalCollections;
  final int totalSizeBytes;

  String get formattedSize {
    if (totalSizeBytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = totalSizeBytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
  }

  factory RommStats.fromJson(Map<String, dynamic> json) {
    int get(String a, String b) =>
        (json[a] as num?)?.toInt() ?? (json[b] as num?)?.toInt() ?? 0;
    return RommStats(
      totalRoms: get('ROMS', 'roms'),
      totalPlatforms: get('PLATFORMS', 'platforms'),
      totalCollections: get('COLLECTIONS', 'collections'),
      totalSizeBytes: get('FILESIZE', 'total_filesize'),
    );
  }
}
