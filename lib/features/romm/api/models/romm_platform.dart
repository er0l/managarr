class RommPlatform {
  const RommPlatform({
    required this.id,
    required this.name,
    required this.displayName,
    required this.slug,
    required this.romCount,
    this.urlLogo,
  });

  final int id;
  final String name;
  final String displayName;
  final String slug;
  final int romCount;
  final String? urlLogo;

  factory RommPlatform.fromJson(Map<String, dynamic> json) {
    return RommPlatform(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      romCount: (json['rom_count'] as num?)?.toInt() ?? 0,
      urlLogo: json['url_logo'] as String?,
    );
  }
}
