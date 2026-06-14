class TautulliLibrary {
  final int sectionId;
  final String sectionName;
  final String sectionType;
  final int count;
  final int? parentCount;
  final int? childCount;
  final int plays;
  final int duration; // total watched seconds
  final int? lastAccessed; // unix timestamp
  final String? art;
  final String? thumb;

  const TautulliLibrary({
    required this.sectionId,
    required this.sectionName,
    required this.sectionType,
    required this.count,
    this.parentCount,
    this.childCount,
    this.plays = 0,
    this.duration = 0,
    this.lastAccessed,
    this.art,
    this.thumb,
  });

  factory TautulliLibrary.fromJson(Map<String, dynamic> json) {
    return TautulliLibrary(
      sectionId: int.tryParse(json['section_id']?.toString() ?? '0') ?? 0,
      sectionName: json['section_name'] ?? 'Unknown',
      sectionType: json['section_type'] ?? 'Unknown',
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      parentCount: int.tryParse(json['parent_count']?.toString() ?? '0'),
      childCount: int.tryParse(json['child_count']?.toString() ?? '0'),
      plays: int.tryParse(json['plays']?.toString() ?? '0') ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      lastAccessed: int.tryParse(json['last_accessed']?.toString() ?? ''),
      art: json['art'] as String?,
      thumb: json['thumb'] as String?,
    );
  }

  // "109 Movies" or "44 Artists · 193 Albums · 3681 Tracks"
  String countDescription() {
    final type = sectionType.toLowerCase();
    final parent = parentCount ?? 0;
    final child = childCount ?? 0;
    switch (type) {
      case 'movie':
        return '$count Movie${count == 1 ? '' : 's'}';
      case 'show':
        final parts = <String>['$count Show${count == 1 ? '' : 's'}'];
        if (parent > 0) parts.add('$parent Season${parent == 1 ? '' : 's'}');
        if (child > 0) parts.add('$child Episode${child == 1 ? '' : 's'}');
        return parts.join(' · ');
      case 'artist':
        final parts = <String>['$count Artist${count == 1 ? '' : 's'}'];
        if (parent > 0) parts.add('$parent Album${parent == 1 ? '' : 's'}');
        if (child > 0) parts.add('$child Track${child == 1 ? '' : 's'}');
        return parts.join(' · ');
      default:
        return '$count Item${count == 1 ? '' : 's'}';
    }
  }

  // "25 Plays · 1 Day 6 Hours 39 Minutes" or "0 Plays · 0 Minutes"
  String playsDescription() {
    final playStr = '$plays Play${plays == 1 ? '' : 's'}';
    final durStr = _formatDuration(duration);
    return '$playStr · $durStr';
  }

  // "3 Months Ago", "8 Days Ago", "Unknown"
  String lastAccessedRelative() {
    final ts = lastAccessed ?? 0;
    if (ts == 0) return 'Unknown';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final diff = DateTime.now().difference(dt);
    final days = diff.inDays;
    if (days > 365) {
      final y = (days / 365).floor();
      return '$y Year${y == 1 ? '' : 's'} Ago';
    }
    if (days > 30) {
      final m = (days / 30).floor();
      return '$m Month${m == 1 ? '' : 's'} Ago';
    }
    if (days > 7) {
      final w = (days / 7).floor();
      return '$w Week${w == 1 ? '' : 's'} Ago';
    }
    if (days > 0) return '$days Day${days == 1 ? '' : 's'} Ago';
    return 'Today';
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 Minutes';
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final parts = <String>[
      if (d > 0) '$d Day${d == 1 ? '' : 's'}',
      if (h > 0) '$h Hour${h == 1 ? '' : 's'}',
      if (m > 0 || (d == 0 && h == 0)) '$m Minute${m == 1 ? '' : 's'}',
    ];
    return parts.join(' ');
  }
}
