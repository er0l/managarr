class RommCollection {
  const RommCollection({
    required this.id,
    required this.name,
    this.description,
    required this.romCount,
  });

  final int id;
  final String name;
  final String? description;
  final int romCount;

  factory RommCollection.fromJson(Map<String, dynamic> json) {
    return RommCollection(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      romCount: (json['rom_count'] as num?)?.toInt() ?? 0,
    );
  }
}
