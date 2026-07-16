/// Auto-generated ("virtual") collection — RomM derives these from ROM
/// metadata (IGDB collections, genres, franchises, companies, modes).
/// Unlike manual collections the id is a string hash.
class RommVirtualCollection {
  const RommVirtualCollection({
    required this.id,
    required this.name,
    required this.type,
    required this.romCount,
    this.description = '',
    this.pathCoversSmall = const [],
  });

  final String id;
  final String name;
  final String type;
  final int romCount;
  final String description;
  final List<String> pathCoversSmall;

  factory RommVirtualCollection.fromJson(Map<String, dynamic> json) {
    return RommVirtualCollection(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? '',
      romCount: (json['rom_count'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      pathCoversSmall: (json['path_covers_small'] as List? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
