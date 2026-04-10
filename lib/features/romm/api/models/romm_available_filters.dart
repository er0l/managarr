/// Available filter options fetched from the ROMM server.
class RommAvailableFilters {
  const RommAvailableFilters({
    this.genres = const [],
    this.franchises = const [],
    this.companies = const [],
    this.ageRatings = const [],
    this.regions = const [],
    this.languages = const [],
  });

  final List<String> genres;
  final List<String> franchises;
  final List<String> companies;
  final List<String> ageRatings;
  final List<String> regions;
  final List<String> languages;

  bool get isEmpty =>
      genres.isEmpty &&
      franchises.isEmpty &&
      companies.isEmpty &&
      ageRatings.isEmpty &&
      regions.isEmpty &&
      languages.isEmpty;

  factory RommAvailableFilters.fromJson(Map<String, dynamic> json) {
    return RommAvailableFilters(
      genres: _parseList(json['genres']),
      franchises: _parseList(json['franchises']),
      companies: _parseList(json['companies']),
      ageRatings: _parseList(json['age_ratings']),
      regions: _parseList(json['regions']),
      languages: _parseList(json['languages']),
    );
  }

  static List<String> _parseList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) return const [];
    return raw.map<String>((e) {
      if (e is String) return e;
      if (e is Map) return e['name']?.toString() ?? '';
      return '';
    }).where((s) => s.isNotEmpty).toList();
  }
}
