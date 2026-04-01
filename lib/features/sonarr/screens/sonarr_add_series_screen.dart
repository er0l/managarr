import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/series.dart';
import '../providers/sonarr_providers.dart';
import 'sonarr_add_series_detail_screen.dart';
import 'sonarr_series_detail_screen.dart';

class SonarrAddSeriesScreen extends ConsumerStatefulWidget {
  const SonarrAddSeriesScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SonarrAddSeriesScreen> createState() =>
      _SonarrAddSeriesScreenState();
}

class _SonarrAddSeriesScreenState extends ConsumerState<SonarrAddSeriesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(sonarrLookupQueryProvider(widget.instance.id).notifier)
          .state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync =
        ref.watch(sonarrLookupResultsProvider(widget.instance));
    final existingAsync = ref.watch(sonarrSeriesProvider(widget.instance));
    final existingByTvdbId = existingAsync.maybeWhen(
      data: (series) => {for (final s in series) s.tvdbId: s},
      orElse: () => <int?, SonarrSeries>{},
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text(
          'Add Series',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.pageHorizontal,
              Spacing.s12,
              Spacing.pageHorizontal,
              Spacing.s8,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for a series…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(sonarrLookupQueryProvider(
                                      widget.instance.id)
                                  .notifier)
                              .state = '';
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Search failed: $e',
                  style: TextStyle(color: AppColors.statusOffline),
                ),
              ),
              data: (results) {
                if (_searchController.text.isEmpty) {
                  return Center(
                    child: Text(
                      'Search for a series to add',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  );
                }
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: Spacing.s24),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final series = results[index];
                    final existing = existingByTvdbId[series.tvdbId];
                    final inLibrary = existing != null;
                    return _SeriesResultTile(
                      series: series,
                      inLibrary: inLibrary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => inLibrary
                              ? SonarrSeriesDetailScreen(
                                  series: existing,
                                  instance: widget.instance,
                                )
                              : SonarrAddSeriesDetailScreen(
                                  series: series,
                                  instance: widget.instance,
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesResultTile extends StatelessWidget {
  const _SeriesResultTile({
    required this.series,
    required this.inLibrary,
    required this.onTap,
  });

  final SonarrSeries series;
  final bool inLibrary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = series.posterUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageHorizontal,
        vertical: 4,
      ),
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 64,
          child: posterUrl != null
              ? Image.network(posterUrl, fit: BoxFit.cover)
              : Container(
                  color: AppColors.tealDark,
                  alignment: Alignment.center,
                  child: Text(
                    series.title.isNotEmpty ? series.title[0] : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(
        series.title,
        style: theme.textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (series.year != null && series.year! > 0)
            Text(
              '${series.year}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          if (inLibrary) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.tealPrimary.withAlpha(80)),
              ),
              child: const Text(
                'In Library',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.tealPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}
