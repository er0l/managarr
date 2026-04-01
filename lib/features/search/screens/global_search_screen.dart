import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/service_type.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../radarr/api/models/movie.dart';
import '../../radarr/providers/radarr_providers.dart';
import '../../radarr/screens/radarr_add_movie_detail_screen.dart';
import '../../radarr/screens/radarr_movie_detail_screen.dart';
import '../../settings/providers/instances_provider.dart';
import '../../sonarr/api/models/series.dart';
import '../../sonarr/providers/sonarr_providers.dart';
import '../../sonarr/screens/sonarr_add_series_detail_screen.dart';
import '../../sonarr/screens/sonarr_series_detail_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  // Per-instance results
  final Map<Instance, AsyncValue<List<RadarrMovie>>> _radarrResults = {};
  final Map<Instance, AsyncValue<List<SonarrSeries>>> _sonarrResults = {};

  // Cached existing library sets for in-library detection
  final Map<Instance, Set<int?>> _sonarrLibraryTvdbIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _radarrResults.clear();
        _sonarrResults.clear();
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value.trim()));
  }

  void _search(String query) {
    final grouped = ref.read(instancesByServiceProvider);
    final radarrInstances = grouped[ServiceType.radarr] ?? [];
    final sonarrInstances = grouped[ServiceType.sonarr] ?? [];

    // Seed loading state
    setState(() {
      for (final inst in radarrInstances) {
        _radarrResults[inst] = const AsyncValue.loading();
      }
      for (final inst in sonarrInstances) {
        _sonarrResults[inst] = const AsyncValue.loading();
      }
    });

    // Fetch Radarr results
    for (final inst in radarrInstances) {
      ref.read(radarrApiProvider(inst)).lookupMovie(query).then((movies) {
        if (mounted) setState(() => _radarrResults[inst] = AsyncValue.data(movies));
      }).catchError((e) {
        if (mounted) setState(() => _radarrResults[inst] = AsyncValue.error(e, StackTrace.current));
      });
    }

    // Fetch Sonarr results + prefetch library tvdbIds for in-library detection
    for (final inst in sonarrInstances) {
      // Grab existing series from cached provider (may already be loaded)
      final existingAsync = ref.read(sonarrSeriesProvider(inst));
      existingAsync.whenData((series) {
        _sonarrLibraryTvdbIds[inst] = series.map((s) => s.tvdbId).toSet();
      });

      ref.read(sonarrApiProvider(inst)).lookupSeries(query).then((series) {
        if (mounted) setState(() => _sonarrResults[inst] = AsyncValue.data(series));
      }).catchError((e) {
        if (mounted) setState(() => _sonarrResults[inst] = AsyncValue.error(e, StackTrace.current));
      });
    }
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      _radarrResults.clear();
      _sonarrResults.clear();
    });
  }

  bool get _isLoading =>
      _radarrResults.values.any((v) => v is AsyncLoading) ||
      _sonarrResults.values.any((v) => v is AsyncLoading);

  bool get _hasQuery => _controller.text.trim().isNotEmpty;

  bool get _hasAnyResults =>
      _radarrResults.values.any((v) => v.valueOrNull?.isNotEmpty == true) ||
      _sonarrResults.values.any((v) => v.valueOrNull?.isNotEmpty == true);

  @override
  Widget build(BuildContext context) {
    // Keep Sonarr library lists fresh for in-library detection
    final grouped = ref.watch(instancesByServiceProvider);
    for (final inst in grouped[ServiceType.sonarr] ?? []) {
      ref.watch(sonarrSeriesProvider(inst)).whenData((series) {
        _sonarrLibraryTvdbIds[inst] = series.map((s) => s.tvdbId).toSet();
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textOnPrimary),
          cursorColor: AppColors.orangeAccent,
          decoration: const InputDecoration(
            hintText: 'Search movies and series…',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_hasQuery)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textOnPrimary),
              tooltip: 'Clear',
              onPressed: _clear,
            ),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.orangeAccent,
                ),
              )
            : null,
      ),
      body: !_hasQuery
          ? _EmptyPrompt()
          : !_isLoading && !_hasAnyResults
              ? _NoResults(query: _controller.text.trim())
              : _ResultsList(
                  radarrResults: _radarrResults,
                  sonarrResults: _sonarrResults,
                  sonarrLibraryTvdbIds: _sonarrLibraryTvdbIds,
                ),
    );
  }
}

// ─── Empty prompt ─────────────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore,
              size: 64, color: AppColors.textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          Text(
            'Search across all Radarr and Sonarr instances',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── No results ───────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No results for "$query"',
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Results list ─────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.radarrResults,
    required this.sonarrResults,
    required this.sonarrLibraryTvdbIds,
  });

  final Map<Instance, AsyncValue<List<RadarrMovie>>> radarrResults;
  final Map<Instance, AsyncValue<List<SonarrSeries>>> sonarrResults;
  final Map<Instance, Set<int?>> sonarrLibraryTvdbIds;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    for (final entry in radarrResults.entries) {
      final inst = entry.key;
      final async = entry.value;
      final movies = async.valueOrNull ?? [];
      if (async is AsyncLoading || movies.isNotEmpty) {
        sections.add(_SectionHeader(
          label: 'Radarr',
          instanceName: inst.name,
        ));
        if (async is AsyncLoading) {
          sections.add(const _LoadingRow());
        } else {
          for (final movie in movies) {
            sections.add(_MovieTile(movie: movie, instance: inst));
          }
        }
      }
    }

    for (final entry in sonarrResults.entries) {
      final inst = entry.key;
      final async = entry.value;
      final series = async.valueOrNull ?? [];
      final libraryIds = sonarrLibraryTvdbIds[inst] ?? {};
      if (async is AsyncLoading || series.isNotEmpty) {
        sections.add(_SectionHeader(
          label: 'Sonarr',
          instanceName: inst.name,
        ));
        if (async is AsyncLoading) {
          sections.add(const _LoadingRow());
        } else {
          for (final s in series) {
            sections.add(_SeriesTile(
              series: s,
              instance: inst,
              inLibrary: libraryIds.contains(s.tvdbId),
            ));
          }
        }
      }
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: sections,
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.instanceName});
  final String label;
  final String instanceName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$label · $instanceName',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.tealDark,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

// ─── Movie tile ───────────────────────────────────────────────────────────────

class _MovieTile extends StatelessWidget {
  const _MovieTile({required this.movie, required this.instance});
  final RadarrMovie movie;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inLibrary = movie.id > 0;
    final posterUrl = movie.posterUrl;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => inLibrary
              ? RadarrMovieDetailScreen(movie: movie, instance: instance)
              : RadarrAddMovieDetailScreen(movie: movie, instance: instance),
        ),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 64,
          child: posterUrl != null
              ? Image.network(posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, _) => _PosterFallback(
                      initial: movie.title.isNotEmpty ? movie.title[0] : 'M'))
              : _PosterFallback(
                  initial: movie.title.isNotEmpty ? movie.title[0] : 'M'),
        ),
      ),
      title: Text(
        movie.title,
        style:
            theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (movie.year > 0) '${movie.year}',
          if (movie.studio != null) movie.studio!,
        ].join(' · '),
        style:
            theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (inLibrary) _InLibraryChip(),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ─── Series tile ──────────────────────────────────────────────────────────────

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({
    required this.series,
    required this.instance,
    required this.inLibrary,
  });
  final SonarrSeries series;
  final Instance instance;
  final bool inLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = series.posterUrl;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => inLibrary
              ? SonarrSeriesDetailScreen(series: series, instance: instance)
              : SonarrAddSeriesDetailScreen(series: series, instance: instance),
        ),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 64,
          child: posterUrl != null
              ? Image.network(posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, _) => _PosterFallback(
                      initial:
                          series.title.isNotEmpty ? series.title[0] : 'S'))
              : _PosterFallback(
                  initial: series.title.isNotEmpty ? series.title[0] : 'S'),
        ),
      ),
      title: Text(
        series.title,
        style:
            theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (series.year != null && series.year! > 0) '${series.year}',
          if (series.network != null) series.network!,
        ].join(' · '),
        style:
            theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (inLibrary) _InLibraryChip(),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      ),
    );
  }
}

class _InLibraryChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusOnline.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.statusOnline.withAlpha(80)),
      ),
      child: const Text(
        'In Library',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.statusOnline,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
