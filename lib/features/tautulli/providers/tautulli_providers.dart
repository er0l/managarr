import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/tautulli_activity.dart';
import '../api/models/tautulli_graph_data.dart';
import '../api/models/tautulli_history.dart';
import '../api/models/tautulli_home_stats.dart';
import '../api/models/tautulli_library.dart';
import '../api/models/tautulli_log_entry.dart';
import '../api/models/tautulli_media_item.dart';
import '../api/models/tautulli_user.dart';
import '../api/models/tautulli_user_detail.dart';
import '../api/tautulli_api.dart';

final tautulliApiProvider =
    Provider.family<TautulliApi, Instance>((ref, instance) {
  return TautulliApi.fromInstance(instance);
});

// ─── Existing providers ───────────────────────────────────────────────────

final tautulliActivityProvider =
    FutureProvider.autoDispose.family<TautulliActivity, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getActivity();
});

final tautulliHistoryProvider =
    FutureProvider.autoDispose.family<TautulliHistory, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getHistory();
});

final tautulliLibrariesProvider =
    FutureProvider.autoDispose.family<List<TautulliLibrary>, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getLibraries();
});

final tautulliUsersProvider =
    FutureProvider.autoDispose.family<List<TautulliUser>, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getUsers();
});

// ─── New providers ────────────────────────────────────────────────────────

final tautulliRecentlyAddedProvider =
    FutureProvider.autoDispose.family<List<TautulliMediaItem>, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getRecentlyAdded();
});

final tautulliHomeStatsProvider =
    FutureProvider.autoDispose.family<TautulliHomeStats, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getHomeStats();
});

typedef TautulliUserKey = ({Instance instance, int userId});

final tautulliUserDetailProvider =
    FutureProvider.autoDispose.family<TautulliUserDetail, TautulliUserKey>(
        (ref, key) async {
  return ref
      .watch(tautulliApiProvider(key.instance))
      .getUserDetail(key.userId);
});

final tautulliUserHistoryProvider =
    FutureProvider.autoDispose.family<TautulliHistory, TautulliUserKey>(
        (ref, key) async {
  return ref
      .watch(tautulliApiProvider(key.instance))
      .getHistory(userId: key.userId);
});

typedef TautulliLibraryKey = ({Instance instance, int sectionId});

final tautulliLibraryMediaProvider = FutureProvider.autoDispose
    .family<List<TautulliMediaItem>, TautulliLibraryKey>((ref, key) async {
  return ref
      .watch(tautulliApiProvider(key.instance))
      .getLibraryMediaInfo(key.sectionId);
});

final tautulliLogsProvider =
    FutureProvider.autoDispose.family<List<TautulliLogEntry>, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getLogs();
});

final tautulliSearchQueryProvider =
    StateProvider.family<String, int>((ref, instanceId) => '');

typedef TautulliSearchKey = ({Instance instance, String query});

final tautulliLibrarySearchProvider = FutureProvider.autoDispose
    .family<Map<String, List<TautulliMediaItem>>, TautulliSearchKey>(
        (ref, args) async {
  if (args.query.trim().isEmpty) return {};
  return ref.watch(tautulliApiProvider(args.instance)).librarySearch(args.query);
});

// ─── Graph providers ──────────────────────────────────────────────────────

final tautulliGraphPlaysByDateProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getGraphPlaysByDate();
});

final tautulliGraphPlaysByMonthProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getGraphPlaysByMonth();
});

final tautulliGraphPlaysByDayOfWeekProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getGraphPlaysByDayOfWeek();
});

final tautulliGraphPlaysByTopPlatformsProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref
      .watch(tautulliApiProvider(instance))
      .getGraphPlaysByTopPlatforms();
});

final tautulliGraphPlaysByTopUsersProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getGraphPlaysByTopUsers();
});

final tautulliGraphStreamTypeByDateProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref.watch(tautulliApiProvider(instance)).getGraphStreamTypeByDate();
});

final tautulliGraphStreamTypeByTopPlatformsProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref
      .watch(tautulliApiProvider(instance))
      .getGraphStreamTypeByTopPlatforms();
});

final tautulliGraphStreamTypeByTopUsersProvider =
    FutureProvider.autoDispose.family<TautulliGraphData, Instance>(
        (ref, instance) async {
  return ref
      .watch(tautulliApiProvider(instance))
      .getGraphStreamTypeByTopUsers();
});
