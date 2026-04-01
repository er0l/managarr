import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/indexer.dart';
import '../api/models/prowlarr_history.dart';
import '../api/models/prowlarr_search_result.dart';
import '../api/prowlarr_api.dart';

final prowlarrApiProvider =
    Provider.family<ProwlarrApi, Instance>((ref, instance) {
  return ProwlarrApi.fromInstance(instance);
});

final prowlarrIndexersProvider =
    FutureProvider.autoDispose.family<List<ProwlarrIndexer>, Instance>(
        (ref, instance) async {
  return ref.read(prowlarrApiProvider(instance)).getIndexers();
});

final prowlarrHealthProvider =
    FutureProvider.autoDispose.family<List<ProwlarrHealthItem>, Instance>(
        (ref, instance) async {
  return ref.read(prowlarrApiProvider(instance)).getHealth();
});

final prowlarrHistoryProvider =
    FutureProvider.autoDispose.family<List<ProwlarrHistoryItem>, Instance>(
        (ref, instance) async {
  return ref.read(prowlarrApiProvider(instance)).getHistory();
});

typedef ProwlarrSearchKey = ({Instance instance, String query});

final prowlarrSearchProvider = FutureProvider.autoDispose
    .family<List<ProwlarrSearchResult>, ProwlarrSearchKey>(
        (ref, key) async {
  if (key.query.isEmpty) return [];
  return ref.read(prowlarrApiProvider(key.instance)).search(key.query);
});
