import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/byte_formatter.dart';
import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_bar_button.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../api/models/artist.dart';
import '../models/lidarr_options.dart';
import '../../settings/providers/ui_prefs_provider.dart';
import '../providers/lidarr_providers.dart';
import 'lidarr_add_artist_screen.dart';
import 'lidarr_artist_detail_screen.dart';
import 'lidarr_missing_albums_screen.dart';

class LidarrHomeScreen extends ConsumerStatefulWidget {
  const LidarrHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<LidarrHomeScreen> createState() => _LidarrHomeScreenState();
}

class _LidarrHomeScreenState extends ConsumerState<LidarrHomeScreen> {
  Future<void> _runCommand(String name, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      await api.sendCommand(name);
      messenger.showSnackBar(SnackBar(
        content: Text('$label started'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSortBottomSheet() {
    final currentSort =
        ref.read(lidarrSortOptionProvider(widget.instance.id));
    final ascending =
        ref.read(lidarrSortAscendingProvider(widget.instance.id));
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Row(
                children: [
                  Text('Sort by', style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: Icon(ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward),
                    onPressed: () {
                      ref
                          .read(lidarrSortAscendingProvider(
                                  widget.instance.id)
                              .notifier)
                          .state = !ascending;
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<LidarrSortOption>(
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(lidarrSortOptionProvider(widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: LidarrSortOption.values
                      .map((o) => RadioListTile<LidarrSortOption>(
                            title: Text(o.label),
                            value: o,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final currentFilter =
        ref.read(lidarrFilterOptionProvider(widget.instance.id));
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text('Filter by',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<LidarrFilterOption>(
                groupValue: currentFilter,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(lidarrFilterOptionProvider(widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: LidarrFilterOption.values
                      .map((o) => RadioListTile<LidarrFilterOption>(
                            title: Text(o.label),
                            value: o,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'History',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: _LidarrHistoryScreen(instance: widget.instance),
        ),
      ),
    );
  }

  void _openMissing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Missing',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: LidarrMissingAlbumsScreen(instance: widget.instance),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMode =
        ref.watch(lidarrDisplayModeProvider(widget.instance.id));
    final currentSort =
        ref.watch(lidarrSortOptionProvider(widget.instance.id));
    final currentFilter =
        ref.watch(lidarrFilterOptionProvider(widget.instance.id));
    final filterActive = currentFilter != LidarrFilterOption.all;
    final sortActive = currentSort != LidarrSortOption.alphabetical;


    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Lidarr',
      tabs: const [],
      tabViews: [_LidarrArtistsScreen(instance: widget.instance)],
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orangeAccent,
        foregroundColor: Colors.white,
        tooltip: 'Add Artist',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LidarrAddArtistScreen(instance: widget.instance),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      appBarActions: [
        IconButton(
          icon: Icon(
            displayMode == DisplayMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
            color: Colors.white,
          ),
          tooltip:
              'Switch to ${displayMode == DisplayMode.grid ? 'List' : 'Grid'}',
          onPressed: () {
            ref
                .read(lidarrDisplayModeProvider(widget.instance.id).notifier)
                .state = displayMode == DisplayMode.grid
                ? DisplayMode.list
                : DisplayMode.grid;
          },
        ),
      ],
      bottomLeadingActions: [
        BottomBarButton(
          icon: Icons.filter_list,
          label: 'Filter',
          active: filterActive,
          onTap: _showFilterBottomSheet,
        ),
        BottomBarButton(
          icon: Icons.sort,
          label: 'Sort',
          active: sortActive,
          onTap: _showSortBottomSheet,
        ),
        BottomBarButton(
          icon: Icons.history,
          label: 'History',
          onTap: _openHistory,
        ),
      ],
      bottomTrailingActions: [
        BottomBarButton(
          icon: Icons.album_outlined,
          label: 'Missing',
          onTap: _openMissing,
        ),
      ],
      bottomMoreItems: const [
        PopupMenuItem(
          value: 'updateLibrary',
          child: ListTile(
            leading: Icon(Icons.folder_open_outlined),
            title: Text('Update Library'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'backup',
          child: ListTile(
            leading: Icon(Icons.backup_outlined),
            title: Text('Backup'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onMoreSelected: (value) {
        switch (value) {
          case 'updateLibrary':
            _runCommand('RescanArtist', 'Update Library');
          case 'backup':
            _runCommand('Backup', 'Backup');
        }
      },
    );
  }
}

// ── Artists screen ───────────────────────────────────────────────────────────

class _LidarrArtistsScreen extends ConsumerStatefulWidget {
  const _LidarrArtistsScreen({required this.instance});
  final Instance instance;

  @override
  ConsumerState<_LidarrArtistsScreen> createState() =>
      _LidarrArtistsScreenState();
}

class _LidarrArtistsScreenState extends ConsumerState<_LidarrArtistsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text =
          ref.read(lidarrSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync =
        ref.watch(lidarrArtistsProvider(widget.instance));
    final filteredArtists =
        ref.watch(lidarrFilteredArtistsProvider(widget.instance));
    final displayMode =
        ref.watch(lidarrDisplayModeProvider(widget.instance.id));
    final query =
        ref.watch(lidarrSearchQueryProvider(widget.instance.id));

    return Column(
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
            decoration: InputDecoration(
              hintText: artistsAsync.value?.length != null
                  ? 'Search ${artistsAsync.value!.length} artists…'
                  : 'Search artists…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(lidarrSearchQueryProvider(
                                    widget.instance.id)
                                .notifier)
                            .state = '';
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: AppColors.tealPrimary.withAlpha(180),
                  width: 1.5,
                ),
              ),
              filled: true,
            ),
            onChanged: (v) => ref
                .read(
                    lidarrSearchQueryProvider(widget.instance.id).notifier)
                .state = v,
          ),
        ),
        Expanded(
          child: artistsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off,
                      size: 48, color: AppColors.statusOffline),
                  const SizedBox(height: Spacing.s12),
                  Text('Could not connect',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: Spacing.s8),
                  FilledButton.icon(
                    onPressed: () => ref
                        .invalidate(lidarrArtistsProvider(widget.instance)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (_) {
              if (filteredArtists.isEmpty) {
                return Center(
                  child: Text(
                    query.isNotEmpty
                        ? 'No results for "$query"'
                        : 'No artists found',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.tealPrimary,
                onRefresh: () async =>
                    ref.invalidate(lidarrArtistsProvider(widget.instance)),
                child: displayMode == DisplayMode.grid
                    ? _ArtistGrid(
                        artists: filteredArtists,
                        instance: widget.instance)
                    : _ArtistList(
                        artists: filteredArtists,
                        instance: widget.instance),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Grid ────────────────────────────────────────────────────────────────────

class _ArtistGrid extends ConsumerWidget {
  const _ArtistGrid({required this.artists, required this.instance});
  final List<LidarrArtist> artists;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal,
        0,
        Spacing.pageHorizontal,
        Spacing.s24,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ref.watch(gridColumnsProvider) +
            (MediaQuery.sizeOf(context).width >= 600 ? 1 : 0),
        crossAxisSpacing: Spacing.cardGap,
        mainAxisSpacing: Spacing.cardGap,
        childAspectRatio: 0.7,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return _ArtistGridCard(artist: artist, instance: instance);
      },
    );
  }
}

class _ArtistGridCard extends StatelessWidget {
  const _ArtistGridCard({required this.artist, required this.instance});
  final LidarrArtist artist;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final posterUrl = artist.posterUrl;
    final theme = Theme.of(context);

    return Opacity(
      opacity: artist.monitored ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LidarrArtistDetailScreen(
                  artist: artist, instance: instance),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (posterUrl != null)
                Image.network(posterUrl, fit: BoxFit.cover)
              else
                Container(
                  color: AppColors.tealDark,
                  alignment: Alignment.center,
                  child: Text(
                    artist.artistName.isNotEmpty
                        ? artist.artistName[0]
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        artist.artistName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (artist.statistics != null)
                        LinearProgressIndicator(
                          value: (artist.statistics!.percentOfTracks ?? 0) /
                              100,
                          backgroundColor:
                              Colors.white.withAlpha(40),
                          color: AppColors.tealPrimary,
                          minHeight: 2,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── List ────────────────────────────────────────────────────────────────────

class _ArtistList extends ConsumerWidget {
  const _ArtistList({required this.artists, required this.instance});
  final List<LidarrArtist> artists;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync =
        ref.watch(lidarrQualityProfilesProvider(instance));
    final profiles = profilesAsync.valueOrNull ?? [];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final profileName = profiles
            .where((p) => p.id == artist.qualityProfileId)
            .map((p) => p.name)
            .firstOrNull;
        return _ArtistTile(
          artist: artist,
          profileName: profileName,
          instance: instance,
        );
      },
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({
    required this.artist,
    required this.profileName,
    required this.instance,
  });

  final LidarrArtist artist;
  final String? profileName;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posterUrl = artist.posterUrl;
    final accentColor = ServiceType.lidarr.brandColor;
    final cardBg =
        isDark ? const Color(0xFF141E2E) : const Color(0xFFF2F4F7);

    final stats = artist.statistics;
    final sizeOnDisk = stats?.sizeOnDisk ?? 0;
    final trackFileCount = stats?.trackFileCount ?? 0;
    final trackCount = stats?.trackCount ?? 0;
    final albumCount = stats?.albumCount ?? 0;
    final pct = stats?.percentOfTracks ?? 0.0;

    final line2Parts = [
      if (artist.artistType != null && artist.artistType!.isNotEmpty)
        artist.artistType!,
      if (albumCount > 0)
        '$albumCount album${albumCount == 1 ? '' : 's'}',
    ];

    final line3Parts = [
      if (profileName != null && profileName!.isNotEmpty) profileName!,
      if (artist.added != null)
        'Added ${DateFormat('MMM y').format(artist.added!)}',
    ].where((s) => s.isNotEmpty).toList();

    return Opacity(
      opacity: artist.monitored ? 1.0 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.pageHorizontal,
          vertical: 4,
        ),
        child: Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LidarrArtistDetailScreen(
                    artist: artist,
                    instance: instance,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Poster / avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: posterUrl != null
                          ? Image.network(posterUrl, fit: BoxFit.cover)
                          : Container(
                              color: AppColors.tealDark,
                              alignment: Alignment.center,
                              child: Text(
                                artist.artistName.isNotEmpty
                                    ? artist.artistName[0]
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line 1: Artist name
                        Text(
                          artist.artistName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Line 2: Type · Albums
                        Text(
                          line2Parts.isEmpty
                              ? '—'
                              : line2Parts.join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Line 3: Profile · Date added
                        Text(
                          line3Parts.isEmpty
                              ? '—'
                              : line3Parts.join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withAlpha(200),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Line 4: icons + track progress + size
                        Row(
                          children: [
                            Icon(
                              artist.monitored
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 14,
                              color: artist.monitored
                                  ? accentColor
                                  : AppColors.textSecondary,
                            ),
                            if (pct >= 100) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: AppColors.statusOnline,
                              ),
                            ],
                            const Spacer(),
                            if (sizeOnDisk > 0) ...[
                              _Chip(
                                label: ByteFormatter.format(sizeOnDisk),
                                color: AppColors.statusOnline,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (trackCount > 0)
                              _Chip(
                                label: '$trackFileCount/$trackCount tracks',
                                color: accentColor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ── History screen ───────────────────────────────────────────────────────────

class _LidarrHistoryScreen extends ConsumerWidget {
  const _LidarrHistoryScreen({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(lidarrHistoryProvider(instance));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (history) {
        if (history.records.isEmpty) {
          return const Center(child: Text('History is empty'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(lidarrHistoryProvider(instance)),
          color: AppColors.tealPrimary,
          child: ListView.builder(
            itemCount: history.records.length,
            itemBuilder: (context, index) {
              final record = history.records[index];
              return ListTile(
                title: Text(record.sourceTitle ?? 'Unknown'),
                subtitle: Text(record.eventType ?? ''),
                trailing: Text(
                  record.date?.toLocal().toString().split('.')[0] ?? '',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
