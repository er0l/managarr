class TautulliLibrary {
  final int sectionId;
  final String sectionName;
  final String sectionType;
  final int count;
  final int? parentCount;
  final int? childCount;

  const TautulliLibrary({
    required this.sectionId,
    required this.sectionName,
    required this.sectionType,
    required this.count,
    this.parentCount,
    this.childCount,
  });

  factory TautulliLibrary.fromJson(Map<String, dynamic> json) {
    return TautulliLibrary(
      sectionId: int.tryParse(json['section_id']?.toString() ?? '0') ?? 0,
      sectionName: json['section_name'] ?? 'Unknown',
      sectionType: json['section_type'] ?? 'Unknown',
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      parentCount: int.tryParse(json['parent_count']?.toString() ?? '0'),
      childCount: int.tryParse(json['child_count']?.toString() ?? '0'),
    );
  }
}
