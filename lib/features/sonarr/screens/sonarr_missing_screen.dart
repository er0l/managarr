import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/series.dart';
import '../providers/sonarr_providers.dart';
import 'sonarr_series_detail_screen.dart';

class SonarrMissingScreen extends ConsumerStatefulWidget {
  const SonarrMissingScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SonarrMissingScreen> createState() =>
      _SonarrMissingScreenState();
}

class _SonarrMissingScreenState extends ConsumerState<SonarrMissingScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isSearchingAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAllMissing() async {
    if (_isSearchingAll) return;
    setState(() => _isSearchingAll = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.sendCommand('MissingEpisodeSearch');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Search all missing episodes started'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSearchingAll = false);
    }
  }

  List<SonarrSeries> _filterMissing(List<SonarrSeries> series) {
    final q = _query.toLowerCase();
    return series
        .where((s) {
          final epCount = s.statistics?.episodeCount ?? 0;
          final fileCount = s.statistics?.episodeFileCount ?? 0;
          final hasMissing = epCount > 0 && epCount != fileCount;
          if (!hasMissing) return false;
          if (q.isNotEmpty && !s.title.toLowerCase().contains(q)) return false;
          return true;
        })
        .toList()
      ..sort((a, b) =>
          (a.sortTitle ?? a.title).toLowerCase().compareTo(
                (b.sortTitle ?? b.title).toLowerCase(),
              ));
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(sonarrSeriesProvider(widget.instance));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search missing…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Search All Missing',
                child: IconButton(
                  icon: _isSearchingAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.travel_explore_outlined),
                  onPressed: _isSearchingAll ? null : _searchAllMissing,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary.withAlpha(20),
                    foregroundColor: AppColors.tealPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: seriesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.statusOffline),
                  const SizedBox(height: 12),
                  Text('$e'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(sonarrSeriesProvider(widget.instance)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (series) {
              final missing = _filterMissing(series);
              if (missing.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: AppColors.statusOnline),
                      SizedBox(height: 12),
                      Text('No missing episodes'),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(sonarrSeriesProvider(widget.instance)),
                color: AppColors.tealPrimary,
                child: ListView.separated(
                  itemCount: missing.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _MissingSeriesTile(
                    series: missing[i],
                    instance: widget.instance,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MissingSeriesTile extends StatelessWidget {
  const _MissingSeriesTile(
      {required this.series, required this.instance});

  final SonarrSeries series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = series.posterUrl;
    final epCount = series.statistics?.episodeCount ?? 0;
    final fileCount = series.statistics?.episodeFileCount ?? 0;
    final missingCount = epCount - fileCount;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SonarrSeriesDetailScreen(series: series, instance: instance),
        ),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 58,
          child: posterUrl != null
              ? Image.network(posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _PosterFallback(series: series))
              : _PosterFallback(series: series),
        ),
      ),
      title: Text(
        series.title,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (series.network != null && series.network!.isNotEmpty) ...[
            Text(series.network!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
          ],
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.statusWarning.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: AppColors.statusWarning.withAlpha(100)),
            ),
            child: Text(
              '$missingCount missing',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.statusWarning),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: AppColors.textSecondary),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.series});
  final SonarrSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        series.title.isNotEmpty ? series.title[0] : '?',
        style: const TextStyle(
            color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
