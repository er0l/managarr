import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/cutoff_record.dart';
import '../providers/sonarr_providers.dart';
import 'sonarr_series_detail_screen.dart';

class SonarrCutoffUnmetScreen extends ConsumerStatefulWidget {
  const SonarrCutoffUnmetScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SonarrCutoffUnmetScreen> createState() =>
      _SonarrCutoffUnmetScreenState();
}

class _SonarrCutoffUnmetScreenState
    extends ConsumerState<SonarrCutoffUnmetScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SonarrCutoffRecord> _filter(List<SonarrCutoffRecord> records) {
    final q = _query.toLowerCase();
    return records
        .where((r) =>
            q.isEmpty ||
            r.seriesTitle.toLowerCase().contains(q) ||
            r.episodeTitle.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) =>
          a.seriesTitle.toLowerCase().compareTo(b.seriesTitle.toLowerCase()));
  }

  void _openSeries(SonarrCutoffRecord record) {
    // Look up the full series from the cached provider for navigation
    final seriesAsync = ref.read(sonarrSeriesProvider(widget.instance));
    final series = seriesAsync.valueOrNull
        ?.where((s) => s.id == record.seriesId)
        .firstOrNull;
    if (series != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SonarrSeriesDetailScreen(series: series, instance: widget.instance),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sonarrCutoffUnmetProvider(widget.instance));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search cutoff unmet…',
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
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                    onPressed: () => ref.invalidate(
                        sonarrCutoffUnmetProvider(widget.instance)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (records) {
              final filtered = _filter(records);
              if (filtered.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: AppColors.statusOnline),
                      SizedBox(height: 12),
                      Text('No cutoff unmet episodes'),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref
                    .invalidate(sonarrCutoffUnmetProvider(widget.instance)),
                color: AppColors.tealPrimary,
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _CutoffEpisodeTile(
                    record: filtered[i],
                    onTap: () => _openSeries(filtered[i]),
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

class _CutoffEpisodeTile extends StatelessWidget {
  const _CutoffEpisodeTile({required this.record, required this.onTap});

  final SonarrCutoffRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 58,
          child: record.seriesPosterUrl != null
              ? Image.network(
                  record.seriesPosterUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _PosterFallback(title: record.seriesTitle),
                )
              : _PosterFallback(title: record.seriesTitle),
        ),
      ),
      title: Text(
        record.seriesTitle,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            '${record.code} · ${record.episodeTitle}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (record.currentQuality != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: AppColors.statusWarning.withAlpha(100)),
              ),
              child: Text(
                record.currentQuality!,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.statusWarning),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: AppColors.textSecondary),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title[0] : '?',
        style: const TextStyle(
            color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
