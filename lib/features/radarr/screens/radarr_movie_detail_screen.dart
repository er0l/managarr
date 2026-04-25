import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/external_link_chips.dart';
import '../../../core/widgets/quality_badge.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';
import 'radarr_edit_movie_screen.dart';
import 'radarr_releases_screen.dart';

class RadarrMovieDetailScreen extends ConsumerStatefulWidget {
  const RadarrMovieDetailScreen({
    super.key,
    required this.movie,
    required this.instance,
  });

  final RadarrMovie movie;
  final Instance instance;

  @override
  ConsumerState<RadarrMovieDetailScreen> createState() =>
      _RadarrMovieDetailScreenState();
}

class _RadarrMovieDetailScreenState
    extends ConsumerState<RadarrMovieDetailScreen>
    with SingleTickerProviderStateMixin {
  late RadarrMovie _movie;
  bool _actionPending = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleMonitor() async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(radarrApiProvider(widget.instance));
      final updated =
          await api.toggleMonitorMovie(_movie.id, !_movie.monitored);
      if (mounted) setState(() => _movie = updated);
      ref.invalidate(radarrMoviesProvider(widget.instance));
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
      final api = ref.read(radarrApiProvider(widget.instance));
      await api.refreshMovie(_movie.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refresh queued'), behavior: SnackBarBehavior.floating),
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

  Future<void> _searchMovie() async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(radarrApiProvider(widget.instance));
      await api.searchMovie(_movie.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search started'), behavior: SnackBarBehavior.floating),
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
      final api = ref.read(radarrApiProvider(widget.instance));
      await api.sendCommand(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label started'), behavior: SnackBarBehavior.floating),
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
    bool deleteFiles = false;
    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Remove Movie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove "${_movie.title}" from Radarr?'),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Delete files from disk'),
                value: deleteFiles,
                onChanged: (v) =>
                    setDialogState(() => deleteFiles = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusOffline),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      setState(() => _actionPending = true);
      try {
        final api = ref.read(radarrApiProvider(widget.instance));
        await api.deleteMovie(_movie.id, deleteFiles: deleteFiles);
        ref.invalidate(radarrMoviesProvider(widget.instance));
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

  void _openEdit() async {
    final updated = await Navigator.push<RadarrMovie>(
      context,
      MaterialPageRoute(
        builder: (_) => RadarrEditMovieScreen(
            movie: _movie, instance: widget.instance),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _movie = updated);
    }
  }

  void _openReleases() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RadarrReleasesScreen(
          instance: widget.instance,
          movieId: _movie.id,
          movieTitle: _movie.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: _BackdropHeader(movie: _movie),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 52),
              title: Text(
                _movie.title,
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
                          strokeWidth: 2, color: AppColors.textOnPrimary)),
                )
              else ...[
                IconButton(
                  icon: Icon(
                    _movie.monitored ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.textOnPrimary,
                  ),
                  tooltip: _movie.monitored ? 'Unmonitor' : 'Monitor',
                  onPressed: _toggleMonitor,
                ),
                IconButton(
                  icon:
                      const Icon(Icons.edit_outlined, color: AppColors.textOnPrimary),
                  tooltip: 'Edit',
                  onPressed: _openEdit,
                ),
                PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert, color: AppColors.textOnPrimary),
                  onSelected: (value) {
                    switch (value) {
                      case 'search':
                        _searchMovie();
                      case 'releases':
                        _openReleases();
                      case 'refresh':
                        _refresh();
                      case 'rescan':
                        _sendCommand('RescanMovie', 'Rescan');
                      case 'rssSync':
                        _sendCommand('RssSync', 'RSS Sync');
                      case 'delete':
                        _confirmDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'search',
                      child: ListTile(
                          leading: Icon(Icons.search),
                          title: Text('Search Movie'),
                          contentPadding: EdgeInsets.zero),
                    ),
                    PopupMenuItem(
                      value: 'releases',
                      child: ListTile(
                          leading: Icon(Icons.download_outlined),
                          title: Text('Releases'),
                          contentPadding: EdgeInsets.zero),
                    ),
                    PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Refresh'),
                          contentPadding: EdgeInsets.zero),
                    ),
                    PopupMenuItem(
                      value: 'rescan',
                      child: ListTile(
                          leading: Icon(Icons.folder_open_outlined),
                          title: Text('Rescan Files'),
                          contentPadding: EdgeInsets.zero),
                    ),
                    PopupMenuItem(
                      value: 'rssSync',
                      child: ListTile(
                          leading: Icon(Icons.rss_feed),
                          title: Text('RSS Sync'),
                          contentPadding: EdgeInsets.zero),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: AppColors.statusOffline),
                          title: Text('Remove Movie',
                              style: TextStyle(color: AppColors.statusOffline)),
                          contentPadding: EdgeInsets.zero),
                    ),
                  ],
                ),
              ],
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.orangeAccent,
              indicatorWeight: 3,
              labelColor: AppColors.textOnPrimary,
              unselectedLabelColor: AppColors.textOnPrimary.withAlpha(160),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Files'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(movie: _movie),
            _FilesTab(instance: widget.instance, movieId: _movie.id),
            _HistoryTab(instance: widget.instance, movieId: _movie.id),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Overview Tab
// =============================================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.movie});
  final RadarrMovie movie;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final links = _buildMovieLinks(movie);
    return ListView(
      padding: const EdgeInsets.all(Spacing.pageHorizontal),
      children: [
        // Banner image (TV-style wide banner; rare for movies but shown when available)
        if (movie.bannerUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              movie.bannerUrl!,
              width: double.infinity,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: Spacing.s16),
        ],
        // Meta chips
        Wrap(
          spacing: Spacing.s8,
          runSpacing: Spacing.s4,
          children: [
            if (movie.year > 0)
              _Chip(label: movie.year.toString(), icon: Icons.calendar_today),
            if (movie.runtime != null && movie.runtime! > 0)
              _Chip(label: '${movie.runtime}m', icon: Icons.timer_outlined),
            if (movie.studio != null)
              _Chip(label: movie.studio!, icon: Icons.business_outlined),
            if (movie.certification != null)
              _Chip(label: movie.certification!, icon: Icons.shield_outlined),
            if (movie.status != null) _StatusChip(status: movie.status!),
            if (movie.hasFile)
              const _Chip(
                  label: 'File on disk',
                  icon: Icons.check_circle_outline,
                  color: AppColors.statusOnline),
            if (!movie.monitored)
              const _Chip(
                  label: 'Unmonitored',
                  icon: Icons.visibility_off_outlined,
                  color: AppColors.statusUnknown),
          ],
        ),
        if (movie.sizeOnDisk != null && movie.sizeOnDisk! > 0) ...[
          const SizedBox(height: Spacing.s4),
          Text(_formatBytes(movie.sizeOnDisk!),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
        if (movie.path != null) ...[
          const SizedBox(height: Spacing.s4),
          Text(movie.path!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary, fontFamily: 'monospace')),
        ],
        const SizedBox(height: Spacing.s16),
        if (movie.overview != null && movie.overview!.isNotEmpty) ...[
          Text('Overview',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: Spacing.s8),
          Text(movie.overview!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.55)),
        ],
        // External links
        if (links.isNotEmpty) ...[
          const SizedBox(height: Spacing.s16),
          ExternalLinksSection(links: links),
        ],
        const SizedBox(height: Spacing.s48),
      ],
    );
  }
}

List<ExternalLink> _buildMovieLinks(RadarrMovie movie) => [
  if (movie.tmdbId != null && movie.tmdbId! > 0)
    ExternalLink(
      label: 'TMDB',
      url: 'https://www.themoviedb.org/movie/${movie.tmdbId}',
      color: const Color(0xFF01B4E4),
    ),
  if (movie.imdbId != null && movie.imdbId!.isNotEmpty) ...[
    ExternalLink(
      label: 'IMDB',
      url: 'https://www.imdb.com/title/${movie.imdbId}/',
      color: const Color(0xFFF5C518),
    ),
    ExternalLink(
      label: 'Trakt',
      url: 'https://trakt.tv/search/imdb/${movie.imdbId}',
      color: const Color(0xFFED1C24),
    ),
    ExternalLink(
      label: 'MovieChat',
      url: 'https://moviechat.org/${movie.imdbId}',
      color: const Color(0xFF607D8B),
    ),
    ExternalLink(
      label: 'MDBList',
      url: 'https://mdblist.com/?q=${movie.imdbId}',
      color: const Color(0xFF1B6EC2),
    ),
  ] else
    ExternalLink(
      label: 'MDBList',
      url:
          'https://mdblist.com/?q=${Uri.encodeComponent(movie.title)}',
      color: const Color(0xFF1B6EC2),
    ),
  ExternalLink(
    label: 'Letterboxd',
    url:
        'https://letterboxd.com/search/films/${Uri.encodeComponent(movie.title)}/',
    color: const Color(0xFF00AC6C),
  ),
  ExternalLink(
    label: 'Blu-ray',
    url: 'https://www.blu-ray.com/search/?quicksearch=1'
        '&quicksearch_keyword=${Uri.encodeComponent(movie.title)}'
        '&section=bluraymovies',
    color: const Color(0xFF1C355E),
  ),
  if (movie.youtubeTrailerId != null &&
      movie.youtubeTrailerId!.isNotEmpty)
    ExternalLink(
      label: 'Trailer',
      url:
          'https://www.youtube.com/watch?v=${movie.youtubeTrailerId}',
      color: const Color(0xFFFF0000),
    ),
];

// =============================================================================
// Files Tab
// =============================================================================

class _FilesTab extends ConsumerWidget {
  const _FilesTab({required this.instance, required this.movieId});
  final Instance instance;
  final int movieId;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(
        radarrMovieFilesProvider((instance: instance, movieId: movieId)));
    final theme = Theme.of(context);

    return filesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.statusOffline))),
      data: (files) {
        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off_outlined,
                    size: 48, color: AppColors.textSecondary.withAlpha(80)),
                const SizedBox(height: Spacing.s16),
                Text('No files found',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async => ref.invalidate(
              radarrMovieFilesProvider((instance: instance, movieId: movieId))),
          child: ListView.builder(
            padding: const EdgeInsets.only(
                top: Spacing.s8, bottom: Spacing.s24),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: Spacing.pageHorizontal, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file.relativePath ?? 'Unknown file',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: Spacing.s8),
                      Wrap(
                        spacing: Spacing.s8,
                        runSpacing: Spacing.s4,
                        children: [
                          QualityBadge(quality: file.qualityName),
                          if (file.size != null && file.size! > 0)
                            _MiniTag(label: _formatBytes(file.size!)),
                          if (file.resolution.isNotEmpty)
                            _MiniTag(label: file.resolution),
                          if (file.videoCodec.isNotEmpty)
                            _MiniTag(label: file.videoCodec),
                          if (file.audioCodec.isNotEmpty)
                            _MiniTag(label: file.audioCodec),
                        ],
                      ),
                      if (file.dateAdded != null) ...[
                        const SizedBox(height: Spacing.s4),
                        Text(
                          'Added ${DateFormat.yMMMd().format(file.dateAdded!)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tealPrimary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tealPrimary.withAlpha(60)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.tealPrimary,
              fontWeight: FontWeight.w500)),
    );
  }
}

// =============================================================================
// History Tab
// =============================================================================

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.instance, required this.movieId});
  final Instance instance;
  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
        radarrMovieHistoryProvider((instance: instance, movieId: movieId)));
    final theme = Theme.of(context);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.statusOffline))),
      data: (history) {
        if (history.records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_outlined,
                    size: 48, color: AppColors.textSecondary.withAlpha(80)),
                const SizedBox(height: Spacing.s16),
                Text('No history',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async => ref.invalidate(
              radarrMovieHistoryProvider((instance: instance, movieId: movieId))),
          child: ListView.builder(
            padding: const EdgeInsets.only(
                top: Spacing.s8, bottom: Spacing.s24),
            itemCount: history.records.length,
            itemBuilder: (context, index) {
              final record = history.records[index];
              return ListTile(
                leading: _HistoryIcon(eventType: record.eventType),
                title: Text(record.sourceTitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    _eventLabel(record.eventType),
                    DateFormat.yMMMd().add_jm().format(record.date),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _eventLabel(String type) => switch (type) {
        'grabbed' => 'Grabbed',
        'downloadFolderImported' => 'Imported',
        'downloadFailed' => 'Failed',
        'movieFileDeleted' => 'Deleted',
        'movieFileRenamed' => 'Renamed',
        _ => type,
      };
}

class _HistoryIcon extends StatelessWidget {
  const _HistoryIcon({required this.eventType});
  final String eventType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (eventType) {
      'grabbed' => (Icons.cloud_download_outlined, AppColors.blueAccent),
      'downloadFolderImported' => (Icons.check_circle_outline, AppColors.statusOnline),
      'downloadFailed' => (Icons.error_outline, AppColors.statusOffline),
      'movieFileDeleted' => (Icons.delete_outline, AppColors.statusOffline),
      'movieFileRenamed' => (Icons.drive_file_rename_outline, AppColors.statusWarning),
      _ => (Icons.info_outline, AppColors.textSecondary),
    };
    return Icon(icon, color: color, size: 24);
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

void _showFullscreenImage(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      pageBuilder: (ctx, anim, secondaryAnim) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({required this.movie});
  final RadarrMovie movie;

  @override
  Widget build(BuildContext context) {
    final fanart = movie.fanartUrl;
    final poster = movie.posterUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (fanart != null)
          GestureDetector(
            onTap: () => _showFullscreenImage(context, fanart),
            child: Image.network(fanart, fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _ColoredFallback(movie: movie)),
          )
        else
          _ColoredFallback(movie: movie),
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
          bottom: 92,
          left: 16,
          child: GestureDetector(
            onTap: poster != null
                ? () => _showFullscreenImage(context, poster)
                : null,
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 8)
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: poster != null
                      ? Image.network(poster, fit: BoxFit.cover)
                      : Container(color: AppColors.tealDark),
                ),
                if (poster != null)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white70,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColoredFallback extends StatelessWidget {
  const _ColoredFallback({required this.movie});
  final RadarrMovie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        movie.title.isNotEmpty ? movie.title[0] : 'R',
        style: const TextStyle(
            color: Colors.white30, fontSize: 96, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, this.color});
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
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: c, fontWeight: FontWeight.w500)),
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
      'released' => AppColors.statusOnline,
      'inCinemas' => AppColors.statusWarning,
      'announced' => AppColors.blueAccent,
      _ => AppColors.statusUnknown,
    };
    final label = switch (status) {
      'released' => 'Released',
      'inCinemas' => 'In Cinemas',
      'announced' => 'Announced',
      _ => status,
    };
    return _Chip(label: label, icon: Icons.movie_outlined, color: color);
  }
}
