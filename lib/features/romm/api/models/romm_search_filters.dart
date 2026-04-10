import 'package:flutter/foundation.dart';

/// Represents the user's active filter selections for a ROMM search.
class RommSearchFilters {
  const RommSearchFilters({
    this.genres = const [],
    this.franchises = const [],
    this.companies = const [],
    this.ageRatings = const [],
    this.regions = const [],
    this.languages = const [],
    this.platformIds = const [],
  });

  final List<String> genres;
  final List<String> franchises;
  final List<String> companies;
  final List<String> ageRatings;
  final List<String> regions;
  final List<String> languages;
  final List<int> platformIds;

  bool get hasActiveFilters =>
      genres.isNotEmpty ||
      franchises.isNotEmpty ||
      companies.isNotEmpty ||
      ageRatings.isNotEmpty ||
      regions.isNotEmpty ||
      languages.isNotEmpty ||
      platformIds.isNotEmpty;

  RommSearchFilters copyWith({
    List<String>? genres,
    List<String>? franchises,
    List<String>? companies,
    List<String>? ageRatings,
    List<String>? regions,
    List<String>? languages,
    List<int>? platformIds,
  }) {
    return RommSearchFilters(
      genres: genres ?? this.genres,
      franchises: franchises ?? this.franchises,
      companies: companies ?? this.companies,
      ageRatings: ageRatings ?? this.ageRatings,
      regions: regions ?? this.regions,
      languages: languages ?? this.languages,
      platformIds: platformIds ?? this.platformIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RommSearchFilters &&
        listEquals(other.genres, genres) &&
        listEquals(other.franchises, franchises) &&
        listEquals(other.companies, companies) &&
        listEquals(other.ageRatings, ageRatings) &&
        listEquals(other.regions, regions) &&
        listEquals(other.languages, languages) &&
        listEquals(other.platformIds, platformIds);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(genres),
        Object.hashAll(franchises),
        Object.hashAll(companies),
        Object.hashAll(ageRatings),
        Object.hashAll(regions),
        Object.hashAll(languages),
        Object.hashAll(platformIds),
      );
}
