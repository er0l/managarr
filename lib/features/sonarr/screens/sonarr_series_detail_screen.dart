import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/external_link_chips.dart';
import '../api/models/series.dart';
import '../providers/sonarr_providers.dart';
import 'sonarr_edit_series_screen.dart';
import 'sonarr_releases_screen.dart';
import 'sonarr_season_detail_screen.dart';

class SonarrSeriesDetailScreen extends ConsumerStatefulWidget {
  const SonarrSeriesDetailScreen({
    super.key,
    required this.series,
    required this.instance,
  });

  final SonarrSeries series;
  final Instance instance;

  @override
  ConsumerState<SonarrSeriesDetailScreen> createState() =>
      _SonarrSeriesDetailScreenState();
}

class _SonarrSeriesDetailScreenState
    extends ConsumerState<SonarrSeriesDetailScreen> {
  late SonarrSeries _series;
  bool _actionPending = false;

  @override
  void initState() {
    super.initState();
    _series = widget.series;
    // The bulk series list may omit per-season statistics.
    // Fetch the full individual record so season episode counts are accurate.
    _fetchFull();
  }

  Future<void> _fetchFull() async {
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      final full = await api.getSeriesById(_series.id);
      if (mounted) setState(() => _series = full);
    } catch (_) {
      // Ignore — the list data already provides a usable fallback.
    }
  }

  Future<void> _toggleMonitor() async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      final updated =
          await api.toggleMonitorSeries(_series.id, !_series.monitored);
      if (mounted) setState(() => _series = updated);
      ref.invalidate(sonarrSeriesProvider(widget.instance));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _actionPending = false);
    }
  }

  Future<void> _refresh() async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.refreshSeries(_series.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refresh queued'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _actionPending = false);
    }
  }

  Future<void> _searchSeries() async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.searchSeries(_series.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search started'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _actionPending = false);
    }
  }

  Future<void> _sendCommand(String name, String label) async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.sendCommand(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label started'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _actionPending = false);
    }
  }

  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Series'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove "${_series.title}" from Sonarr?'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (ctx, setInnerState) {
                bool deleteFiles = false;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Delete files from disk'),
                      value: deleteFiles,
                      onChanged: (v) => setInnerState(() => deleteFiles = v ?? false),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.statusOffline,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      setState(() => _actionPending = true);
      try {
        final api = ref.read(sonarrApiProvider(widget.instance));
        await api.deleteSeries(_series.id);
        ref.invalidate(sonarrSeriesProvider(widget.instance));
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
          );
          setState(() => _actionPending = false);
        }
      }
    });
  }

  Widget _buildExternalLinks() {
    final links = <ExternalLink>[
      if (_series.tvdbId != null && _series.tvdbId! > 0)
        ExternalLink(
          label: 'TVDB',
          url: 'https://www.thetvdb.com/?id=${_series.tvdbId}&tab=series',
          color: const Color(0xFF6DBE45),
        ),
      if (_series.imdbId != null && _series.imdbId!.isNotEmpty)
        ExternalLink(
          label: 'IMDB',
          url: 'https://www.imdb.com/title/${_series.imdbId}/',
          color: const Color(0xFFF5C518),
        ),
      if (_series.tmdbId != null && _series.tmdbId! > 0)
        ExternalLink(
          label: 'TMDB',
          url: 'https://www.themoviedb.org/tv/${_series.tmdbId}',
          color: const Color(0xFF01B4E4),
        ),
      if (_series.tvdbId != null && _series.tvdbId! > 0)
        ExternalLink(
          label: 'Trakt',
          url:
              'https://trakt.tv/search/tvdb/${_series.tvdbId}?id_type=show',
          color: const Color(0xFFED1C24),
        ),
      if (_series.tvMazeId != null && _series.tvMazeId! > 0)
        ExternalLink(
          label: 'TVMaze',
          url: 'https://www.tvmaze.com/shows/${_series.tvMazeId}',
          color: const Color(0xFFEAB83C),
        ),
      ExternalLink(
        label: 'MDBList',
        url: _series.imdbId != null && _series.imdbId!.isNotEmpty
            ? 'https://mdblist.com/?q=${_series.imdbId}'
            : 'https://mdblist.com/?q=${Uri.encodeComponent(_series.title)}',
        color: const Color(0xFF1B6EC2),
      ),
    ];
    return ExternalLinksSection(links: links);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seasons = (_series.seasons ?? [])
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: _BackdropHeader(series: _series),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              title: Text(
                _series.title,
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: [
              if (_actionPending)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textOnPrimary),
                  tooltip: 'Edit',
                  onPressed: () async {
                    final updated = await Navigator.push<SonarrSeries>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SonarrEditSeriesScreen(
                          series: _series,
                          instance: widget.instance,
                        ),
                      ),
                    );
                    if (updated != null && mounted) {
                      setState(() => _series = updated);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    _series.monitored
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: AppColors.textOnPrimary,
                  ),
                  tooltip: _series.monitored ? 'Unmonitor' : 'Monitor',
                  onPressed: _toggleMonitor,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textOnPrimary),
                  onSelected: (value) {
                    switch (value) {
                      case 'search':
                        _searchSeries();
                      case 'releases':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SonarrReleasesScreen(
                              series: _series,
                              instance: widget.instance,
                            ),
                          ),
                        );
                      case 'updateLibrary':
                        _sendCommand('RescanSeries', 'Rescan');
                      case 'rssSync':
                        _sendCommand('RssSync', 'RSS Sync');
                      case 'delete':
                        _confirmDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'search',
                      child: ListTile(
                        leading: Icon(Icons.search),
                        title: Text('Search Monitored'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'releases',
                      child: ListTile(
                        leading: Icon(Icons.cloud_download_outlined),
                        title: Text('Releases'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'updateLibrary',
                      child: ListTile(
                        leading: Icon(Icons.folder_open_outlined),
                        title: Text('Rescan Files'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rssSync',
                      child: ListTile(
                        leading: Icon(Icons.rss_feed),
                        title: Text('RSS Sync'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline,
                            color: AppColors.statusOffline),
                        title: Text(
                          'Remove Series',
                          style: TextStyle(color: AppColors.statusOffline),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.pageHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta chips
                  Wrap(
                    spacing: Spacing.s8,
                    runSpacing: Spacing.s4,
                    children: [
                      if (_series.year != null && _series.year! > 0)
                        _Chip(
                          label: _series.year.toString(),
                          icon: Icons.calendar_today,
                        ),
                      if (_series.runtime != null && _series.runtime! > 0)
                        _Chip(
                          label: '${_series.runtime}m',
                          icon: Icons.timer_outlined,
                        ),
                      if (_series.network != null)
                        _Chip(
                          label: _series.network!,
                          icon: Icons.tv_outlined,
                        ),
                      if (_series.seasonCount != null)
                        _Chip(
                          label:
                              '${_series.seasonCount} season${_series.seasonCount == 1 ? '' : 's'}',
                          icon: Icons.layers_outlined,
                        ),
                      if (_series.status != null)
                        _StatusChip(status: _series.status!),
                      if (!_series.monitored)
                        const _Chip(
                          label: 'Unmonitored',
                          icon: Icons.visibility_off_outlined,
                          color: AppColors.statusUnknown,
                        ),
                    ],
                  ),

                  // Size on disk
                  if ((_series.statistics?.sizeOnDisk ?? 0) > 0) ...[
                    const SizedBox(height: Spacing.s4),
                    Text(
                      _formatBytes(_series.statistics!.sizeOnDisk!),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],

                  // Overview
                  if (_series.overview != null &&
                      _series.overview!.isNotEmpty) ...[
                    const SizedBox(height: Spacing.s16),
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Spacing.s8),
                    Text(
                      _series.overview!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],

                  // External links
                  const SizedBox(height: Spacing.s16),
                  _buildExternalLinks(),

                  // Seasons
                  if (seasons.isNotEmpty) ...[
                    const SizedBox(height: Spacing.s24),
                    Text(
                      'Seasons',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Spacing.s8),
                  ],
                ],
              ),
            ),
          ),

          // Season list
          if (seasons.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SeasonTile(
                  season: seasons[index],
                  series: _series,
                  instance: widget.instance,
                ),
                childCount: seasons.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: Spacing.s48)),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ---------------------------------------------------------------------------

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({required this.series});

  final SonarrSeries series;

  @override
  Widget build(BuildContext context) {
    final fanart = series.fanartUrl;
    final poster = series.posterUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (fanart != null)
          Image.network(
            fanart,
            fit: BoxFit.cover,
            errorBuilder: (e, s, t) => _ColoredFallback(series: series),
          )
        else
          _ColoredFallback(series: series),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.4, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 52,
          left: 16,
          child: Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
            ),
            clipBehavior: Clip.antiAlias,
            child: poster != null
                ? Image.network(poster, fit: BoxFit.cover)
                : Container(color: AppColors.tealDark),
          ),
        ),
      ],
    );
  }
}

class _ColoredFallback extends StatelessWidget {
  const _ColoredFallback({required this.series});
  final SonarrSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        series.title.isNotEmpty ? series.title[0] : 'S',
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 96,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SeasonTile extends StatelessWidget {
  const _SeasonTile({
    required this.season,
    required this.series,
    required this.instance,
  });
  final SonarrSeason season;
  final SonarrSeries series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = season.statistics;
    final fileCount = stats?.episodeFileCount ?? 0;
    final totalCount = stats?.totalEpisodeCount ?? 0;
    final percent = totalCount > 0
        ? fileCount / totalCount
        : 1.0;
    final label = season.seasonNumber == 0
        ? 'Specials'
        : 'Season ${season.seasonNumber}';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SonarrSeasonDetailScreen(
            series: series,
            season: season,
            instance: instance,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.pageHorizontal,
          vertical: Spacing.s8,
        ),
        child: Row(
          children: [
            Icon(
              season.monitored ? Icons.bookmark : Icons.bookmark_border,
              size: 18,
              color: season.monitored
                  ? AppColors.tealPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: Spacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: AppColors.tealPrimary.withAlpha(30),
                    color: percent >= 1.0
                        ? AppColors.statusOnline
                        : AppColors.tealPrimary,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$fileCount / $totalCount episodes',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.tealPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'continuing' => AppColors.statusOnline,
      'ended' => AppColors.statusOffline,
      'upcoming' => AppColors.blueAccent,
      _ => AppColors.statusUnknown,
    };
    final label = switch (status) {
      'continuing' => 'Continuing',
      'ended' => 'Ended',
      'upcoming' => 'Upcoming',
      _ => status[0].toUpperCase() + status.substring(1),
    };
    return _Chip(label: label, icon: Icons.circle, color: color);
  }
}
