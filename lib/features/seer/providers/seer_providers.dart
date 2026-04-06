import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/seer_api.dart';
import '../api/models/media_detail.dart';
import '../api/models/media_request.dart';
import '../api/models/search_result.dart';
import '../api/models/seer_issue.dart';
import '../api/models/seer_user.dart';

import '../../../core/models/display_mode.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum SeerRequestSort {
  newest('Newest First'),
  oldest('Oldest First'),
  titleAz('Title A–Z'),
  titleZa('Title Z–A');

  const SeerRequestSort(this.label);
  final String label;
}

enum SeerRequestStatusFilter {
  all('All'),
  pending('Pending'),
  approved('Approved'),
  declined('Declined'),
  partiallyAvailable('Partially Available'),
  available('Available');

  const SeerRequestStatusFilter(this.label);
  final String label;
}

// ─── Core providers ──────────────────────────────────────────────────────────

final seerApiProvider =
    Provider.family<SeerApi, Instance>((ref, instance) {
  return SeerApi.fromInstance(instance);
});

/// Persists the display mode (Grid/List) for Seer.
final seerDisplayModeProvider =
    StateProvider.family<DisplayMode, int>((ref, instanceId) => DisplayMode.grid);

// ─── Requests providers ──────────────────────────────────────────────────────

final seerRequestsProvider =
    FutureProvider.autoDispose.family<List<SeerMediaRequest>, Instance>(
        (ref, instance) async {
  final api = ref.read(seerApiProvider(instance));
  return api.getRequests();
});

final seerRequestsSearchQueryProvider =
    StateProvider.family<String, int>((ref, instanceId) => '');

final seerRequestsStatusFilterProvider =
    StateProvider.family<SeerRequestStatusFilter, int>(
        (ref, instanceId) => SeerRequestStatusFilter.all);

final seerRequestsSortProvider =
    StateProvider.family<SeerRequestSort, int>(
        (ref, instanceId) => SeerRequestSort.newest);

final seerFilteredRequestsProvider =
    Provider.autoDispose.family<List<SeerMediaRequest>, Instance>(
        (ref, instance) {
  final requestsAsync = ref.watch(seerRequestsProvider(instance));
  final query = ref.watch(seerRequestsSearchQueryProvider(instance.id));
  final statusFilter = ref.watch(seerRequestsStatusFilterProvider(instance.id));
  final sort = ref.watch(seerRequestsSortProvider(instance.id));

  final all = requestsAsync.valueOrNull ?? [];
  var filtered = all.where((r) {
    if (query.isNotEmpty &&
        !r.title.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    final statusMatch = switch (statusFilter) {
      SeerRequestStatusFilter.all => true,
      SeerRequestStatusFilter.pending => r.status == 1,
      SeerRequestStatusFilter.approved => r.status == 2,
      SeerRequestStatusFilter.declined => r.status == 3,
      SeerRequestStatusFilter.partiallyAvailable => r.status == 4,
      SeerRequestStatusFilter.available => r.status == 5,
    };
    return statusMatch;
  }).toList();

  switch (sort) {
    case SeerRequestSort.newest:
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case SeerRequestSort.oldest:
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case SeerRequestSort.titleAz:
      filtered.sort((a, b) => a.title.compareTo(b.title));
    case SeerRequestSort.titleZa:
      filtered.sort((a, b) => b.title.compareTo(a.title));
  }
  return filtered;
});

// ─── Discover providers ──────────────────────────────────────────────────────

enum SeerDiscoverSort {
  defaultOrder('Default'),
  titleAz('Title A → Z'),
  titleZa('Title Z → A'),
  yearNewest('Year: Newest first'),
  yearOldest('Year: Oldest first'),
  ratingHighest('Rating: Highest first'),
  ratingLowest('Rating: Lowest first');

  const SeerDiscoverSort(this.label);
  final String label;
}

final seerDiscoverSearchQueryProvider =
    StateProvider.family<String, int>((ref, instanceId) => '');

final seerDiscoverSortProvider =
    StateProvider.family<SeerDiscoverSort, int>(
        (ref, instanceId) => SeerDiscoverSort.defaultOrder);

final seerDiscoverMoviesProvider =
    FutureProvider.autoDispose.family<List<SeerSearchResult>, Instance>(
        (ref, instance) async {
  final api = ref.read(seerApiProvider(instance));
  return api.getDiscoverMovies();
});

final seerDiscoverTvProvider =
    FutureProvider.autoDispose.family<List<SeerSearchResult>, Instance>(
        (ref, instance) async {
  final api = ref.read(seerApiProvider(instance));
  return api.getDiscoverTv();
});

// ─── Search provider ─────────────────────────────────────────────────────────

typedef SeerSearchKey = ({Instance instance, String query});

final seerSearchProvider = FutureProvider.autoDispose
    .family<List<SeerSearchResult>, SeerSearchKey>(
        (ref, key) async {
  if (key.query.isEmpty) return [];
  final api = ref.read(seerApiProvider(key.instance));
  return api.search(key.query);
});

// ─── Filtered discover providers ─────────────────────────────────────────────

final seerFilteredDiscoverMoviesProvider = Provider.autoDispose
    .family<AsyncValue<List<SeerSearchResult>>, Instance>((ref, instance) {
  final query = ref.watch(seerDiscoverSearchQueryProvider(instance.id)).trim();
  final sort = ref.watch(seerDiscoverSortProvider(instance.id));

  final AsyncValue<List<SeerSearchResult>> raw = query.isEmpty
      ? ref.watch(seerDiscoverMoviesProvider(instance))
      : ref
          .watch(seerSearchProvider((instance: instance, query: query)))
          .whenData((r) => r.where((x) => x.mediaType == 'movie').toList());

  return raw.whenData((list) => _sortDiscover(list, sort));
});

final seerFilteredDiscoverTvProvider = Provider.autoDispose
    .family<AsyncValue<List<SeerSearchResult>>, Instance>((ref, instance) {
  final query = ref.watch(seerDiscoverSearchQueryProvider(instance.id)).trim();
  final sort = ref.watch(seerDiscoverSortProvider(instance.id));

  final AsyncValue<List<SeerSearchResult>> raw = query.isEmpty
      ? ref.watch(seerDiscoverTvProvider(instance))
      : ref
          .watch(seerSearchProvider((instance: instance, query: query)))
          .whenData((r) => r.where((x) => x.mediaType == 'tv').toList());

  return raw.whenData((list) => _sortDiscover(list, sort));
});

List<SeerSearchResult> _sortDiscover(
    List<SeerSearchResult> list, SeerDiscoverSort sort) {
  final sorted = List.of(list);
  switch (sort) {
    case SeerDiscoverSort.defaultOrder:
      break;
    case SeerDiscoverSort.titleAz:
      sorted.sort((a, b) => a.title.compareTo(b.title));
    case SeerDiscoverSort.titleZa:
      sorted.sort((a, b) => b.title.compareTo(a.title));
    case SeerDiscoverSort.yearNewest:
      sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    case SeerDiscoverSort.yearOldest:
      sorted.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
    case SeerDiscoverSort.ratingHighest:
      sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    case SeerDiscoverSort.ratingLowest:
      sorted.sort((a, b) => a.voteAverage.compareTo(b.voteAverage));
  }
  return sorted;
}

// ─── Issues providers ────────────────────────────────────────────────────────

final seerIssuesProvider =
    FutureProvider.autoDispose.family<List<SeerIssue>, Instance>(
        (ref, instance) async {
  final api = ref.read(seerApiProvider(instance));
  return api.getIssues(pageSize: 100);
});

enum SeerIssueStatusFilter { all, open, resolved }
enum SeerIssueTypeFilter { all, video, audio, subtitle, other }

final seerIssueStatusFilterProvider =
    StateProvider.family<SeerIssueStatusFilter, int>(
        (ref, instanceId) => SeerIssueStatusFilter.all);

final seerIssueTypeFilterProvider =
    StateProvider.family<SeerIssueTypeFilter, int>(
        (ref, instanceId) => SeerIssueTypeFilter.all);

final seerFilteredIssuesProvider =
    Provider.autoDispose.family<List<SeerIssue>, Instance>((ref, instance) {
  final issuesAsync = ref.watch(seerIssuesProvider(instance));
  final statusFilter = ref.watch(seerIssueStatusFilterProvider(instance.id));
  final typeFilter = ref.watch(seerIssueTypeFilterProvider(instance.id));

  final all = issuesAsync.valueOrNull ?? [];
  return all.where((issue) {
    final statusOk = switch (statusFilter) {
      SeerIssueStatusFilter.all => true,
      SeerIssueStatusFilter.open => issue.isOpen,
      SeerIssueStatusFilter.resolved => !issue.isOpen,
    };
    final typeOk = switch (typeFilter) {
      SeerIssueTypeFilter.all => true,
      SeerIssueTypeFilter.video => issue.issueType == 1,
      SeerIssueTypeFilter.audio => issue.issueType == 2,
      SeerIssueTypeFilter.subtitle => issue.issueType == 3,
      SeerIssueTypeFilter.other => issue.issueType == 4,
    };
    return statusOk && typeOk;
  }).toList();
});

// ─── Users providers ─────────────────────────────────────────────────────────

final seerUsersProvider =
    FutureProvider.autoDispose.family<List<SeerUser>, Instance>(
        (ref, instance) async {
  final api = ref.read(seerApiProvider(instance));
  return api.getUsers();
});

typedef SeerUserRequestsKey = ({Instance instance, int userId});

final seerUserRequestsProvider = FutureProvider.autoDispose
    .family<List<SeerMediaRequest>, SeerUserRequestsKey>(
        (ref, key) async {
  final api = ref.read(seerApiProvider(key.instance));
  return api.getUserRequests(key.userId);
});

// ─── Media detail provider ───────────────────────────────────────────────────

typedef SeerMediaKey = ({Instance instance, int tmdbId, String mediaType});

final seerMediaDetailProvider = FutureProvider.autoDispose
    .family<SeerMediaDetail?, SeerMediaKey>((ref, key) async {
  final api = ref.read(seerApiProvider(key.instance));
  if (key.mediaType == 'movie') {
    return api.getMovie(key.tmdbId);
  } else {
    return api.getTv(key.tmdbId);
  }
});
