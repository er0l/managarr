import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/artist.dart';
import '../api/models/album.dart';
import '../providers/lidarr_providers.dart';
import 'lidarr_album_screen.dart';
import 'lidarr_edit_artist_screen.dart';

class LidarrArtistDetailScreen extends ConsumerStatefulWidget {
  const LidarrArtistDetailScreen({
    super.key,
    required this.artist,
    required this.instance,
  });

  final LidarrArtist artist;
  final Instance instance;

  @override
  ConsumerState<LidarrArtistDetailScreen> createState() =>
      _LidarrArtistDetailScreenState();
}

class _LidarrArtistDetailScreenState
    extends ConsumerState<LidarrArtistDetailScreen> {
  late LidarrArtist _artist;
  bool _actionPending = false;

  @override
  void initState() {
    super.initState();
    _artist = widget.artist;
  }

  Future<void> _toggleMonitor() async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      final updated =
          await api.toggleMonitorArtist(_artist.id, !_artist.monitored);
      if (mounted) setState(() => _artist = updated);
      ref.invalidate(lidarrArtistsProvider(widget.instance));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
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
      final api = ref.read(lidarrApiProvider(widget.instance));
      await api.refreshArtist(_artist.id);
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
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
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
        title: const Text('Remove Artist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove "${_artist.artistName}" from Lidarr?'),
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
                      onChanged: (v) =>
                          setInnerState(() => deleteFiles = v ?? false),
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
                              backgroundColor: AppColors.statusOffline),
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
        final api = ref.read(lidarrApiProvider(widget.instance));
        await api.deleteArtist(_artist.id);
        ref.invalidate(lidarrArtistsProvider(widget.instance));
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _actionPending = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final albumsAsync =
        ref.watch(lidarrAlbumsProvider((widget.instance, _artist.id)));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: _BackdropHeader(artist: _artist),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              title: Text(
                _artist.artistName,
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textOnPrimary),
                  tooltip: 'Edit',
                  onPressed: () async {
                    final updated = await Navigator.push<LidarrArtist>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LidarrEditArtistScreen(
                          artist: _artist,
                          instance: widget.instance,
                        ),
                      ),
                    );
                    if (updated != null && mounted) {
                      setState(() => _artist = updated);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    _artist.monitored
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: AppColors.textOnPrimary,
                  ),
                  tooltip: _artist.monitored ? 'Unmonitor' : 'Monitor',
                  onPressed: _toggleMonitor,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textOnPrimary),
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textOnPrimary),
                  onSelected: (value) {
                    switch (value) {
                      case 'search':
                        _doSearch();
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
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline,
                            color: AppColors.statusOffline),
                        title: Text('Remove Artist',
                            style:
                                TextStyle(color: AppColors.statusOffline)),
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
                      if (_artist.artistType != null)
                        _Chip(
                            label: _artist.artistType!,
                            icon: Icons.music_note_outlined),
                      if ((_artist.statistics?.albumCount ?? 0) > 0)
                        _Chip(
                          label:
                              '${_artist.statistics!.albumCount} album${_artist.statistics!.albumCount == 1 ? '' : 's'}',
                          icon: Icons.album_outlined,
                        ),
                      if ((_artist.statistics?.sizeOnDisk ?? 0) > 0)
                        _Chip(
                          label: _formatBytes(
                              _artist.statistics!.sizeOnDisk!),
                          icon: Icons.storage_outlined,
                        ),
                      if (!_artist.monitored)
                        const _Chip(
                          label: 'Unmonitored',
                          icon: Icons.visibility_off_outlined,
                          color: AppColors.statusUnknown,
                        ),
                    ],
                  ),

                  if (_artist.overview != null &&
                      _artist.overview!.isNotEmpty) ...[
                    const SizedBox(height: Spacing.s16),
                    Text('Overview',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: Spacing.s8),
                    Text(
                      _artist.overview!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],

                  const SizedBox(height: Spacing.s24),
                  Text('Albums',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: Spacing.s8),
                ],
              ),
            ),
          ),

          albumsAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
                child: Center(child: Text(e.toString()))),
            data: (albums) {
              if (albums.isEmpty) {
                return const SliverFillRemaining(
                    child: Center(child: Text('No albums found')));
              }
              final sorted = [...albums]
                ..sort((a, b) {
                  final da = a.releaseDate ?? DateTime(0);
                  final db = b.releaseDate ?? DateTime(0);
                  return db.compareTo(da);
                });
              return SliverPadding(
                padding:
                    const EdgeInsets.only(bottom: Spacing.s48),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _AlbumTile(
                      album: sorted[index],
                      instance: widget.instance,
                      artistName: _artist.artistName,
                    ),
                    childCount: sorted.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _doSearch() async {
    if (_actionPending) return;
    setState(() => _actionPending = true);
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      await api.searchArtist(_artist.id);
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
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionPending = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({required this.artist});
  final LidarrArtist artist;

  @override
  Widget build(BuildContext context) {
    final fanart = artist.fanartUrl;
    final poster = artist.posterUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (fanart != null)
          Image.network(fanart, fit: BoxFit.cover,
              errorBuilder: (e, s, t) => _ColoredFallback(artist: artist))
        else
          _ColoredFallback(artist: artist),
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
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 8)
              ],
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
  const _ColoredFallback({required this.artist});
  final LidarrArtist artist;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        artist.artistName.isNotEmpty ? artist.artistName[0] : 'A',
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 96,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.album,
    required this.instance,
    required this.artistName,
  });

  final LidarrAlbum album;
  final Instance instance;
  final String artistName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = album.statistics;
    final fileCount = stats?.trackFileCount ?? 0;
    final trackCount = stats?.trackCount ?? 0;
    final percent =
        trackCount > 0 ? fileCount / trackCount : (fileCount > 0 ? 1.0 : 0.0);
    final year = album.releaseDate?.year;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LidarrAlbumScreen(
            album: album,
            instance: instance,
            artistName: artistName,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.pageHorizontal, vertical: Spacing.s8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 52,
                height: 52,
                child: album.coverUrl != null
                    ? Image.network(album.coverUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.tealDark,
                        alignment: Alignment.center,
                        child: const Icon(Icons.album,
                            color: Colors.white54, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: Spacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (year != null)
                        Text('$year',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      if (year != null && trackCount > 0)
                        Text(' · ',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      if (trackCount > 0)
                        Text('$fileCount/$trackCount tracks',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: AppColors.tealPrimary.withAlpha(30),
                    color: percent >= 1.0
                        ? AppColors.statusOnline
                        : AppColors.tealPrimary,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
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
