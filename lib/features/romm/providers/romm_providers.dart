import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/romm_available_filters.dart';
import '../api/models/romm_collection.dart';
import '../api/models/romm_platform.dart';
import '../api/models/romm_rom.dart';
import '../api/models/romm_search_filters.dart';
import '../api/romm_api.dart';

final rommApiProvider = Provider.family<RommApi, Instance>(
    (ref, instance) => RommApi.fromInstance(instance));

// ---------------------------------------------------------------------------
// Platforms
// ---------------------------------------------------------------------------

final rommPlatformsProvider =
    FutureProvider.autoDispose.family<List<RommPlatform>, Instance>(
        (ref, instance) =>
            ref.watch(rommApiProvider(instance)).getPlatforms());

// ---------------------------------------------------------------------------
// Collections
// ---------------------------------------------------------------------------

final rommCollectionsProvider =
    FutureProvider.autoDispose.family<List<RommCollection>, Instance>(
        (ref, instance) =>
            ref.watch(rommApiProvider(instance)).getCollections());

// ---------------------------------------------------------------------------
// ROMs — platform browsing
// ---------------------------------------------------------------------------

typedef RommRomsKey = ({Instance instance, int platformId, String searchTerm});

final rommRomsProvider = FutureProvider.autoDispose
    .family<List<RommRom>, RommRomsKey>((ref, key) {
  final api = ref.watch(rommApiProvider(key.instance));
  return api.getRoms(
    key.platformId,
    searchTerm: key.searchTerm.isEmpty ? null : key.searchTerm,
  );
});

// ---------------------------------------------------------------------------
// ROMs — collection browsing
// ---------------------------------------------------------------------------

typedef RommCollectionRomsKey = ({
  Instance instance,
  int collectionId,
  String searchTerm
});

final rommCollectionRomsProvider = FutureProvider.autoDispose
    .family<List<RommRom>, RommCollectionRomsKey>((ref, key) {
  final api = ref.watch(rommApiProvider(key.instance));
  return api.getCollectionRoms(
    key.collectionId,
    searchTerm: key.searchTerm.isEmpty ? null : key.searchTerm,
  );
});

// ---------------------------------------------------------------------------
// ROMs — global search with filters
// ---------------------------------------------------------------------------

typedef RommSearchKey = ({
  Instance instance,
  String searchTerm,
  RommSearchFilters filters,
});

final rommSearchProvider = FutureProvider.autoDispose
    .family<List<RommRom>, RommSearchKey>((ref, key) {
  final api = ref.watch(rommApiProvider(key.instance));
  return api.searchRoms(
    key.searchTerm.isEmpty ? null : key.searchTerm,
    key.filters,
  );
});

// ---------------------------------------------------------------------------
// ROM detail
// ---------------------------------------------------------------------------

final rommRomDetailProvider = FutureProvider.autoDispose
    .family<RommRom, ({Instance instance, int romId})>(
        (ref, key) =>
            ref.watch(rommApiProvider(key.instance)).getRomDetail(key.romId));

// ---------------------------------------------------------------------------
// Available filters
// ---------------------------------------------------------------------------

final rommAvailableFiltersProvider =
    FutureProvider.autoDispose.family<RommAvailableFilters, Instance>(
        (ref, instance) =>
            ref.watch(rommApiProvider(instance)).getAvailableFilters());
