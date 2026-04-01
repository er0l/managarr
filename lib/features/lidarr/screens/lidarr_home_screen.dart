import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../api/models/artist.dart';
import '../models/lidarr_options.dart';
import '../providers/lidarr_providers.dart';
import '../widgets/artist_card.dart';
import 'lidarr_add_artist_screen.dart';
import 'lidarr_artist_detail_screen.dart';
import 'lidarr_missing_albums_screen.dart';

class LidarrHomeScreen extends ConsumerStatefulWidget {
  const LidarrHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<LidarrHomeScreen> createState() => _LidarrHomeScreenState();
}

class _LidarrHomeScreenState extends ConsumerState<LidarrHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;

  static const _tabs = ['Artists', 'History', 'Missing'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runCommand(String name, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      await api.sendCommand(name);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$label started'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMode = ref.watch(lidarrDisplayModeProvider(widget.instance.id));

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Lidarr',
      tabs: _tabs,
      tabController: _tabController,
      actions: [
        IconButton(
          icon: Icon(
            displayMode == DisplayMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
            color: AppColors.textOnPrimary,
          ),
          tooltip: 'Switch to ${displayMode == DisplayMode.grid ? 'List' : 'Grid'}',
          onPressed: () {
            ref.read(lidarrDisplayModeProvider(widget.instance.id).notifier).state =
                displayMode == DisplayMode.grid ? DisplayMode.list : DisplayMode.grid;
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textOnPrimary),
          onSelected: (value) {
            switch (value) {
              case 'updateLibrary':
                _runCommand('RescanArtist', 'Update Library');
              case 'backup':
                _runCommand('Backup', 'Backup');
            }
          },
          itemBuilder: (context) => const [
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
        ),
      ],
      tabViews: [
        _LidarrArtistsTab(instance: widget.instance),
        _LidarrHistoryTab(instance: widget.instance),
        LidarrMissingAlbumsScreen(instance: widget.instance),
      ],
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
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
            )
          : null,
    );
  }
}

class _LidarrArtistsTab extends ConsumerStatefulWidget {
  const _LidarrArtistsTab({required this.instance});
  final Instance instance;

  @override
  ConsumerState<_LidarrArtistsTab> createState() => _LidarrArtistsTabState();
}

class _LidarrArtistsTabState extends ConsumerState<_LidarrArtistsTab> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(lidarrSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet() {
    final currentSort = ref.read(lidarrSortOptionProvider(widget.instance.id));
    final ascending = ref.read(lidarrSortAscendingProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Row(
                children: [
                  Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () {
                      ref.read(lidarrSortAscendingProvider(widget.instance.id).notifier).state = !ascending;
                      Navigator.pop(context);
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
                    ref.read(lidarrSortOptionProvider(widget.instance.id).notifier).state = val;
                    Navigator.pop(context);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: LidarrSortOption.values
                      .map((option) => RadioListTile<LidarrSortOption>(
                            title: Text(option.label),
                            value: option,
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
    final currentFilter = ref.read(lidarrFilterOptionProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text('Filter by', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<LidarrFilterOption>(
                groupValue: currentFilter,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(lidarrFilterOptionProvider(widget.instance.id).notifier).state = val;
                    Navigator.pop(context);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: LidarrFilterOption.values
                      .map((option) => RadioListTile<LidarrFilterOption>(
                            title: Text(option.label),
                            value: option,
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

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(lidarrArtistsProvider(widget.instance));
    final filteredArtists = ref.watch(lidarrFilteredArtistsProvider(widget.instance));
    final displayMode = ref.watch(lidarrDisplayModeProvider(widget.instance.id));
    final query = ref.watch(lidarrSearchQueryProvider(widget.instance.id));
    final currentSort = ref.watch(lidarrSortOptionProvider(widget.instance.id));
    final currentFilter = ref.watch(lidarrFilterOptionProvider(widget.instance.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal,
            Spacing.s12,
            Spacing.pageHorizontal,
            Spacing.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search artists…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(lidarrSearchQueryProvider(widget.instance.id).notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => ref.read(lidarrSearchQueryProvider(widget.instance.id).notifier).state = v,
                ),
              ),
              const SizedBox(width: Spacing.s8),
              _ControlButton(
                icon: Icons.filter_list,
                isActive: currentFilter != LidarrFilterOption.all,
                onTap: _showFilterBottomSheet,
              ),
              const SizedBox(width: Spacing.s4),
              _ControlButton(
                icon: Icons.sort,
                isActive: currentSort != LidarrSortOption.alphabetical,
                onTap: _showSortBottomSheet,
              ),
            ],
          ),
        ),
        Expanded(
          child: artistsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (_) {
              if (filteredArtists.isEmpty) {
                return Center(
                  child: Text(
                    query.isNotEmpty ? 'No results for "$query"' : 'No artists found',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(lidarrArtistsProvider(widget.instance)),
                child: displayMode == DisplayMode.grid
                    ? _ArtistGrid(artists: filteredArtists, instance: widget.instance)
                    : _ArtistList(artists: filteredArtists, instance: widget.instance),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.isActive, required this.onTap});
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      onPressed: onTap,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? colorScheme.primaryContainer : null,
        foregroundColor: isActive ? colorScheme.onPrimaryContainer : null,
      ),
      icon: Icon(icon),
    );
  }
}

class _ArtistGrid extends StatelessWidget {
  const _ArtistGrid({required this.artists, required this.instance});
  final List<LidarrArtist> artists;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal, vertical: Spacing.s12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Spacing.cardGap,
        mainAxisSpacing: Spacing.cardGap,
        childAspectRatio: 0.7,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ArtistCard(
          artist: artist,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LidarrArtistDetailScreen(
                artist: artist,
                instance: instance,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtistList extends StatelessWidget {
  const _ArtistList({required this.artists, required this.instance});
  final List<LidarrArtist> artists;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: artist.posterUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(artist.posterUrl!))
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Text(artist.artistName),
          subtitle: Text(artist.artistType ?? ''),
          trailing: Text(artist.statistics?.trackCount?.toString() ?? '0'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LidarrArtistDetailScreen(
                artist: artist,
                instance: instance,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LidarrHistoryTab extends ConsumerWidget {
  const _LidarrHistoryTab({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(lidarrHistoryProvider(instance));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (history) {
        if (history.records.isEmpty) {
          return const Center(child: Text('History is empty'));
        }
        return ListView.builder(
          itemCount: history.records.length,
          itemBuilder: (context, index) {
            final record = history.records[index];
            return ListTile(
              title: Text(record.sourceTitle ?? 'Unknown'),
              subtitle: Text(record.eventType ?? ''),
              trailing: Text(record.date?.toLocal().toString().split('.')[0] ?? ''),
            );
          },
        );
      },
    );
  }
}
