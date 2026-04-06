class SonarrImportList {
  final int id;
  final String name;
  final bool enabled;
  final bool enableAuto;
  final String listType;
  /// Full raw JSON — used when PUTting the object back to toggle enabled.
  final Map<String, dynamic> raw;

  const SonarrImportList({
    required this.id,
    required this.name,
    required this.enabled,
    required this.enableAuto,
    required this.listType,
    required this.raw,
  });

  factory SonarrImportList.fromJson(Map<String, dynamic> json) {
    return SonarrImportList(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      enabled: json['enabled'] == true,
      enableAuto: json['enableAuto'] == true,
      listType: json['listType'] as String? ?? '',
      raw: json,
    );
  }

  SonarrImportList copyWith({bool? enabled}) {
    return SonarrImportList(
      id: id,
      name: name,
      enabled: enabled ?? this.enabled,
      enableAuto: enableAuto,
      listType: listType,
      raw: Map<String, dynamic>.from(raw)..['enabled'] = enabled ?? this.enabled,
    );
  }
}
