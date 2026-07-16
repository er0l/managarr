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
    this.favourite,
    this.matched,
    this.duplicate,
    this.playable,
    this.missing,
  });

  final List<String> genres;
  final List<String> franchises;
  final List<String> companies;
  final List<String> ageRatings;
  final List<String> regions;
  final List<String> languages;
  final List<int> platformIds;

  // Tri-state toggles: null = don't filter, true/false = require value.
  final bool? favourite;
  final bool? matched;
  final bool? duplicate;
  final bool? playable;
  final bool? missing;

  bool get hasActiveFilters =>
      genres.isNotEmpty ||
      franchises.isNotEmpty ||
      companies.isNotEmpty ||
      ageRatings.isNotEmpty ||
      regions.isNotEmpty ||
      languages.isNotEmpty ||
      platformIds.isNotEmpty ||
      favourite != null ||
      matched != null ||
      duplicate != null ||
      playable != null ||
      missing != null;

  static const _unset = Object();

  RommSearchFilters copyWith({
    List<String>? genres,
    List<String>? franchises,
    List<String>? companies,
    List<String>? ageRatings,
    List<String>? regions,
    List<String>? languages,
    List<int>? platformIds,
    Object? favourite = _unset,
    Object? matched = _unset,
    Object? duplicate = _unset,
    Object? playable = _unset,
    Object? missing = _unset,
  }) {
    return RommSearchFilters(
      genres: genres ?? this.genres,
      franchises: franchises ?? this.franchises,
      companies: companies ?? this.companies,
      ageRatings: ageRatings ?? this.ageRatings,
      regions: regions ?? this.regions,
      languages: languages ?? this.languages,
      platformIds: platformIds ?? this.platformIds,
      favourite:
          identical(favourite, _unset) ? this.favourite : favourite as bool?,
      matched: identical(matched, _unset) ? this.matched : matched as bool?,
      duplicate:
          identical(duplicate, _unset) ? this.duplicate : duplicate as bool?,
      playable:
          identical(playable, _unset) ? this.playable : playable as bool?,
      missing: identical(missing, _unset) ? this.missing : missing as bool?,
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
        listEquals(other.platformIds, platformIds) &&
        other.favourite == favourite &&
        other.matched == matched &&
        other.duplicate == duplicate &&
        other.playable == playable &&
        other.missing == missing;
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
        favourite,
        matched,
        duplicate,
        playable,
        missing,
      );
}
