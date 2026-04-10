import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/episode.dart';
import '../api/models/series.dart';
import '../providers/sonarr_providers.dart';
import 'sonarr_releases_screen.dart';

class SonarrSeasonDetailScreen extends ConsumerWidget {
  const SonarrSeasonDetailScreen({
    super.key,
    required this.series,
    required this.season,
    required this.instance,
  });

  final SonarrSeries series;
  final SonarrSeason season;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(sonarrEpisodesProvider((
      instance: instance,
      seriesId: series.id,
      seasonNumber: season.seasonNumber,
    )));

    final label = season.seasonNumber == 0
        ? 'Specials'
        : 'Season ${season.seasonNumber}';

    // Prefer the wide banner image; fall back to fanart if no banner.
    final headerImageUrl = series.bannerUrl ?? series.fanartUrl;

    final actions = [
      IconButton(
        icon: const Icon(Icons.search, color: AppColors.textOnPrimary),
        tooltip: 'Search Season',
        onPressed: () => _searchSeason(context, ref),
      ),
      IconButton(
        icon: const Icon(Icons.cloud_download_outlined,
            color: AppColors.textOnPrimary),
        tooltip: 'Season Releases',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SonarrReleasesScreen(
              series: series,
              instance: instance,
              seasonNumber: season.seasonNumber,
              title: label,
            ),
          ),
        ),
      ),
    ];

    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        Text(series.title,
            style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w400)),
      ],
    );

    Widget buildBody(List<SonarrEpisode> episodes) {
      if (episodes.isEmpty) {
        return Center(
          child: Text('No episodes found',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary)),
        );
      }
      final sorted = [...episodes]
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return ListView.builder(
        padding: const EdgeInsets.only(top: Spacing.s8, bottom: Spacing.s24),
        itemCount: sorted.length,
        itemBuilder: (context, index) => _EpisodeTile(
          episode: sorted[index],
          series: series,
          instance: instance,
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: headerImageUrl != null ? 180 : null,
            pinned: true,
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
            flexibleSpace: headerImageUrl != null
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          headerImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: AppColors.tealPrimary),
                        ),
                        // Gradient so collapsed title text stays readable.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ],
                    ),
                    titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 52),
                    title: titleWidget,
                  )
                : null,
            // When no image, show title inline in the AppBar.
            title: headerImageUrl == null ? titleWidget : null,
            actions: actions,
          ),
        ],
        body: episodesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off,
                      size: 48, color: AppColors.statusOffline),
                  const SizedBox(height: Spacing.s16),
                  Text('Failed to load episodes',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: Spacing.s8),
                  Text(e.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                      maxLines: 3),
                  const SizedBox(height: Spacing.s24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(sonarrEpisodesProvider((
                      instance: instance,
                      seriesId: series.id,
                      seasonNumber: season.seasonNumber,
                    ))),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: const StadiumBorder()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: buildBody,
        ),
      ),
    );
  }

  Future<void> _searchSeason(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(sonarrApiProvider(instance));
      await api.searchSeason(series.id, season.seasonNumber);
      messenger.showSnackBar(const SnackBar(
        content: Text('Season search started'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── Episode tile ─────────────────────────────────────────────────────────────

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.series,
    required this.instance,
  });

  final SonarrEpisode episode;
  final SonarrSeries series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = episode.hasFile;
    final airDate = episode.airDate;
    String? formattedDate;
    if (airDate != null) {
      try {
        formattedDate = DateFormat.yMMMd().format(DateTime.parse(airDate));
      } catch (_) {}
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.pageHorizontal, vertical: 4),
      onTap: () => _showEpisodeSheet(context),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.statusOnline.withAlpha(20)
              : AppColors.textSecondary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFile
                ? AppColors.statusOnline.withAlpha(60)
                : AppColors.textSecondary.withAlpha(40),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          episode.episodeNumber.toString(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: hasFile ? AppColors.statusOnline : AppColors.textSecondary,
          ),
        ),
      ),
      title: Text(
        episode.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: hasFile ? null : AppColors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: formattedDate != null
          ? Text(formattedDate,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!episode.monitored)
            const Icon(Icons.bookmark_border,
                size: 16, color: AppColors.textSecondary),
          if (hasFile)
            const Icon(Icons.check_circle_outline,
                size: 16, color: AppColors.statusOnline),
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _showEpisodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EpisodeDetailSheet(
        episode: episode,
        series: series,
        instance: instance,
      ),
    );
  }
}

// ─── Episode detail bottom sheet ──────────────────────────────────────────────

class _EpisodeDetailSheet extends ConsumerStatefulWidget {
  const _EpisodeDetailSheet({
    required this.episode,
    required this.series,
    required this.instance,
  });

  final SonarrEpisode episode;
  final SonarrSeries series;
  final Instance instance;

  @override
  ConsumerState<_EpisodeDetailSheet> createState() =>
      _EpisodeDetailSheetState();
}

class _EpisodeDetailSheetState extends ConsumerState<_EpisodeDetailSheet> {
  bool _searching = false;

  Future<void> _searchEpisode() async {
    if (_searching) return;
    setState(() => _searching = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.searchEpisode(widget.episode.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Episode search started'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _searching = false);
      }
    }
  }

  void _openReleases() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SonarrReleasesScreen(
          series: widget.series,
          instance: widget.instance,
          episodeId: widget.episode.id,
          title:
              'E${widget.episode.episodeNumber.toString().padLeft(2, '0')} – ${widget.episode.title}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ep = widget.episode;
    final hasFile = ep.hasFile;
    final epCode =
        'S${ep.seasonNumber.toString().padLeft(2, '0')}E${ep.episodeNumber.toString().padLeft(2, '0')}';

    String? formattedDate;
    if (ep.airDate != null) {
      try {
        formattedDate = DateFormat.yMMMd().format(DateTime.parse(ep.airDate!));
      } catch (_) {}
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Episode code + title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.tealPrimary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppColors.tealPrimary.withAlpha(60)),
                  ),
                  child: Text(epCode,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.tealPrimary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(ep.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Meta row
            Row(
              children: [
                if (formattedDate != null) ...[
                  const Icon(Icons.calendar_today,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(formattedDate,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                ],
                if (hasFile) ...[
                  const Icon(Icons.check_circle_outline,
                      size: 12, color: AppColors.statusOnline),
                  const SizedBox(width: 4),
                  Text(
                    ep.episodeFile?.qualityName.isNotEmpty == true
                        ? ep.episodeFile!.qualityName
                        : 'Downloaded',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.statusOnline),
                  ),
                ] else ...[
                  const Icon(Icons.download_outlined,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Missing',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
                if (!ep.monitored) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.bookmark_border,
                      size: 12, color: AppColors.statusUnknown),
                  const SizedBox(width: 4),
                  Text('Unmonitored',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.statusUnknown)),
                ],
              ],
            ),

            // Overview
            if (ep.overview != null && ep.overview!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(ep.overview!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary, height: 1.5),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _searching ? null : _searchEpisode,
                    icon: _searching
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search, size: 18),
                    label:
                        Text(_searching ? 'Searching…' : 'Search Episode'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.tealPrimary,
                      side: const BorderSide(color: AppColors.tealPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openReleases,
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('Releases'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
