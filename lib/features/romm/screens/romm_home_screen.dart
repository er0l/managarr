import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_bar_button.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../api/models/romm_available_filters.dart';
import '../api/models/romm_collection.dart';
import '../api/models/romm_platform.dart';
import '../api/models/romm_rom.dart';
import '../api/models/romm_search_filters.dart';
import '../api/romm_api.dart';
import '../providers/romm_providers.dart';
import '../widgets/rom_rail.dart';
import 'romm_collection_screen.dart';
import 'romm_downloads_screen.dart';
import 'romm_platform_screen.dart';
import 'romm_rom_detail_screen.dart';
import 'romm_stats_screen.dart';
import 'romm_virtual_collection_screen.dart';

class RommHomeScreen extends ConsumerStatefulWidget {
  const RommHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<RommHomeScreen> createState() => _RommHomeScreenState();
}

class _RommHomeScreenState extends ConsumerState<RommHomeScreen> {
  Future<void> _rescan() async {
    final api = ref.read(rommApiProvider(widget.instance));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await api.scanLibrary();
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Library scan started'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Scan failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _openCollections() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Collections',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: _CollectionsScreen(instance: widget.instance),
        ),
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    // Open the sheet immediately; filter options load inside it so the
    // button gives instant feedback even on a slow connection.
    final api = ref.read(rommApiProvider(widget.instance));
    final current = ref.read(rommHomeFiltersProvider(widget.instance.id));
    final updated = await showModalBottomSheet<RommSearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder<RommAvailableFilters>(
        // Called directly to avoid autoDispose provider recycling the future.
        future: api.getAvailableFilters(),
        builder: (context, snap) {
          if (!snap.hasData && !snap.hasError) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return _FilterSheet(
            current: current,
            available: snap.data ?? const RommAvailableFilters(),
          );
        },
      ),
    );
    if (updated != null && mounted) {
      ref.read(rommHomeFiltersProvider(widget.instance.id).notifier).state =
          updated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMode =
        ref.watch(rommHomeDisplayModeProvider(widget.instance.id));
    final filters = ref.watch(rommHomeFiltersProvider(widget.instance.id));

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'ROMM',
      tabs: const [],
      tabViews: [_RommMainView(instance: widget.instance)],
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
                .read(rommHomeDisplayModeProvider(widget.instance.id).notifier)
                .state = displayMode == DisplayMode.grid
                ? DisplayMode.list
                : DisplayMode.grid;
          },
        ),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: ServiceType.romm.brandColor,
        foregroundColor: Colors.white,
        tooltip: 'Refresh',
        onPressed: () {
          ref.invalidate(rommPlatformsProvider(widget.instance));
          ref.invalidate(rommStatsProvider(widget.instance));
          ref.invalidate(rommCollectionsProvider(widget.instance));
        },
        child: const Icon(Icons.refresh),
      ),
      bottomLeadingActions: [
        BottomBarButton(
          icon: Icons.tune_outlined,
          label: 'Filter',
          active: filters.hasActiveFilters,
          onTap: _showFilterSheet,
        ),
      ],
      bottomTrailingActions: [
        BottomBarButton(
          icon: Icons.folder_outlined,
          label: 'Collections',
          onTap: _openCollections,
        ),
      ],
      bottomMoreItems: const [
        PopupMenuItem(
          value: 'stats',
          child: ListTile(
            leading: Icon(Icons.leaderboard_outlined),
            title: Text('Statistics'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'downloads',
          child: ListTile(
            leading: Icon(Icons.download_done_outlined),
            title: Text('Downloads'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'rescan',
          child: ListTile(
            leading: Icon(Icons.radar_outlined),
            title: Text('Rescan Library'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      onMoreSelected: (value) {
        switch (value) {
          case 'rescan':
            _rescan();
          case 'stats':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RommStatsScreen(instance: widget.instance),
              ),
            );
          case 'downloads':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RommDownloadsScreen(instance: widget.instance),
              ),
            );
        }
      },
    );
  }
}

// ── Main view: platforms + unified search ────────────────────────────────────

class _RommMainView extends ConsumerStatefulWidget {
  const _RommMainView({required this.instance});
  final Instance instance;

  @override
  ConsumerState<_RommMainView> createState() => _RommMainViewState();
}

class _RommMainViewState extends ConsumerState<_RommMainView> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    setState(() => _searchTerm = v.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchTerm = '');
  }

  @override
  Widget build(BuildContext context) {
    final filters =
        ref.watch(rommHomeFiltersProvider(widget.instance.id));
    final isSearching = _searchTerm.isNotEmpty || filters.hasActiveFilters;

    final statsAsync = ref.watch(rommStatsProvider(widget.instance));
    final stats = statsAsync.valueOrNull;
    final hintText = stats != null
        ? 'Search ${stats.totalRoms} ROMs and ${stats.totalPlatforms} platforms'
        : 'Search ROMs and platforms…';

    final displayMode =
        ref.watch(rommHomeDisplayModeProvider(widget.instance.id));

    return Column(
      children: [
        // Search bar
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
              hintText: hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clearSearch,
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
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
          ),
        ),

        // Active filter chips
        if (filters.hasActiveFilters)
          _ActiveFilterChips(
            filters: filters,
            onClear: () => ref
                .read(rommHomeFiltersProvider(widget.instance.id).notifier)
                .state = const RommSearchFilters(),
          ),

        // Body: platforms or ROM search results
        Expanded(
          child: isSearching
              ? _RomSearchResults(
                  instance: widget.instance,
                  searchTerm: _searchTerm,
                  filters: filters,
                )
              : _PlatformsView(
                  instance: widget.instance,
                  displayMode: displayMode,
                ),
        ),
      ],
    );
  }
}

// ── Platforms view (grid + list) ─────────────────────────────────────────────

class _PlatformsView extends ConsumerWidget {
  const _PlatformsView({required this.instance, required this.displayMode});
  final Instance instance;
  final DisplayMode displayMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformsAsync = ref.watch(rommPlatformsProvider(instance));
    final api = ref.watch(rommApiProvider(instance));

    return platformsAsync.when(
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
              onPressed: () => ref.invalidate(rommPlatformsProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (platforms) {
        final visible = platforms.where((p) => p.romCount > 0).toList();
        if (visible.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videogame_asset_outlined,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No platforms found'),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(rommPlatformsProvider(instance));
            ref.invalidate(rommRecentlyPlayedProvider(instance));
            ref.invalidate(rommRecentlyAddedProvider(instance));
          },
          color: AppColors.tealPrimary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: RomRail(
                  title: 'Continue Playing',
                  instance: instance,
                  romsAsync: ref.watch(rommRecentlyPlayedProvider(instance)),
                ),
              ),
              SliverToBoxAdapter(
                child: RomRail(
                  title: 'Recently Added',
                  instance: instance,
                  romsAsync: ref.watch(rommRecentlyAddedProvider(instance)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.pageHorizontal,
                    Spacing.s12,
                    Spacing.pageHorizontal,
                    0,
                  ),
                  child: Text(
                    'Platforms',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (displayMode == DisplayMode.grid)
                _PlatformsGrid(
                    platforms: visible, instance: instance, api: api)
              else
                _PlatformsList(
                    platforms: visible, instance: instance, api: api),
              const SliverToBoxAdapter(
                  child: SizedBox(height: Spacing.s24)),
            ],
          ),
        );
      },
    );
  }
}

class _PlatformsGrid extends StatelessWidget {
  const _PlatformsGrid(
      {required this.platforms, required this.instance, required this.api});
  final List<RommPlatform> platforms;
  final Instance instance;
  final RommApi api;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _PlatformCard(
            platform: platforms[i],
            instance: instance,
            api: api,
          ),
          childCount: platforms.length,
        ),
      ),
    );
  }
}

class _PlatformsList extends StatelessWidget {
  const _PlatformsList(
      {required this.platforms, required this.instance, required this.api});
  final List<RommPlatform> platforms;
  final Instance instance;
  final RommApi api;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 4, bottom: Spacing.s24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _PlatformListTile(
            platform: platforms[i],
            instance: instance,
            api: api,
          ),
          childCount: platforms.length,
        ),
      ),
    );
  }
}

class _PlatformListTile extends StatelessWidget {
  const _PlatformListTile(
      {required this.platform, required this.instance, required this.api});
  final RommPlatform platform;
  final Instance instance;
  final RommApi api;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg =
        isDark ? const Color(0xFF141E2E) : const Color(0xFFF2F4F7);

    final githubSvgUrl =
        'https://raw.githubusercontent.com/rommapp/romm/master/frontend/assets/platforms/${platform.slug}.svg';
    final rawLogoUrl = platform.urlLogo;
    String? fallbackUrl;
    Map<String, String>? fallbackHeaders;
    if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
      final isExternal = rawLogoUrl.startsWith('http');
      fallbackUrl =
          isExternal ? rawLogoUrl : '${instance.baseUrl}$rawLogoUrl';
      if (!isExternal) {
        final encoded = base64.encode(utf8.encode(instance.apiKey));
        fallbackHeaders = {'Authorization': 'Basic $encoded'};
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.pageHorizontal, vertical: 4),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RommPlatformScreen(
                  instance: instance, platform: platform),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: _PlatformLogo(
                    slug: platform.slug,
                    githubSvgUrl: githubSvgUrl,
                    fallbackUrl: fallbackUrl,
                    fallbackHeaders: fallbackHeaders,
                    platformName: platform.displayName,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform.displayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${platform.romCount} ROMs',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ROM search results ────────────────────────────────────────────────────────

class _RomSearchResults extends ConsumerWidget {
  const _RomSearchResults({
    required this.instance,
    required this.searchTerm,
    required this.filters,
  });
  final Instance instance;
  final String searchTerm;
  final RommSearchFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      instance: instance,
      searchTerm: searchTerm,
      filters: filters,
    );
    final romsAsync = ref.watch(rommSearchProvider(key));
    final api = ref.watch(rommApiProvider(instance));

    return romsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            Text('$e'),
          ],
        ),
      ),
      data: (roms) {
        if (roms.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_outlined,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No ROMs found'),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: roms.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) => _SearchRomTile(
            rom: roms[i],
            api: api,
            instance: instance,
          ),
        );
      },
    );
  }
}

class _SearchRomTile extends StatelessWidget {
  const _SearchRomTile(
      {required this.rom, required this.api, required this.instance});
  final RommRom rom;
  final RommApi api;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final coverUrl = api.coverUrl(rom);
    final isExternal = rom.urlCover != null && rom.urlCover!.isNotEmpty;

    Widget cover;
    if (coverUrl != null) {
      cover = Image.network(
        coverUrl,
        width: 48,
        height: 64,
        fit: BoxFit.cover,
        headers: isExternal ? null : {'Authorization': api.authHeader},
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      cover = _placeholder();
    }

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(width: 48, height: 64, child: cover),
      ),
      title: Text(
        rom.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          rom.platformDisplayName,
          if (rom.releaseYear != null) rom.releaseYear.toString(),
          if (rom.averageRating != null && rom.averageRating! > 0)
            '★ ${rom.averageRating!.toStringAsFixed(1)}',
        ].where((s) => s.isNotEmpty).join(' · '),
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RommRomDetailScreen(
            instance: instance,
            romId: rom.id,
            romName: rom.name,
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.tealPrimary.withAlpha(20),
        child: const Icon(Icons.videogame_asset_outlined,
            color: AppColors.tealPrimary, size: 24),
      );
}

// ── Collections screen (push) ────────────────────────────────────────────────

class _CollectionsScreen extends ConsumerStatefulWidget {
  const _CollectionsScreen({required this.instance});
  final Instance instance;

  @override
  ConsumerState<_CollectionsScreen> createState() =>
      _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<_CollectionsScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  /// false = manual collections, true = auto (virtual) collections.
  bool _showVirtual = false;
  String _virtualType = 'collection';

  static const _virtualTypes = {
    'collection': 'Series',
    'genre': 'Genres',
    'franchise': 'Franchises',
    'company': 'Companies',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateDialog(RommApi api) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    final desc = descCtrl.text.trim();
    nameCtrl.dispose();
    descCtrl.dispose();
    if (confirmed != true || !mounted) return;
    if (name.isEmpty) return;
    try {
      await api.createCollection(name,
          description: desc.isEmpty ? null : desc);
      ref.invalidate(rommCollectionsProvider(widget.instance));
      messenger.showSnackBar(SnackBar(
        content: Text('Collection "$name" created'),
        backgroundColor: AppColors.statusOnline,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Failed to create collection: $e'),
        backgroundColor: AppColors.statusOffline,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync =
        ref.watch(rommCollectionsProvider(widget.instance));
    final api = ref.watch(rommApiProvider(widget.instance));

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.pageHorizontal, 12, Spacing.pageHorizontal, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search collections…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchTerm = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
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
                onChanged: (v) =>
                    setState(() => _searchTerm = v.toLowerCase()),
              ),
            ),
            // Manual vs auto-generated collections
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pageHorizontal, vertical: 4),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.folder_outlined, size: 16),
                    label: Text('Manual'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.auto_awesome_outlined, size: 16),
                    label: Text('Auto'),
                  ),
                ],
                selected: {_showVirtual},
                onSelectionChanged: (s) =>
                    setState(() => _showVirtual = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.tealPrimary,
                  selectedForegroundColor: AppColors.textOnPrimary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            if (_showVirtual)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.pageHorizontal),
                  children: [
                    for (final entry in _virtualTypes.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value,
                              style: const TextStyle(fontSize: 12)),
                          selected: _virtualType == entry.key,
                          showCheckmark: false,
                          selectedColor: AppColors.tealPrimary,
                          labelStyle: TextStyle(
                            color: _virtualType == entry.key
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          onSelected: (_) =>
                              setState(() => _virtualType = entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            if (_showVirtual)
              Expanded(
                child: _VirtualCollectionsList(
                  instance: widget.instance,
                  type: _virtualType,
                  searchTerm: _searchTerm,
                ),
              )
            else
            Expanded(
              child: collectionsAsync.when(
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
                        onPressed: () => ref.invalidate(
                            rommCollectionsProvider(widget.instance)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (collections) {
                  final filtered = _searchTerm.isEmpty
                      ? collections
                      : collections
                          .where((c) => c.name
                              .toLowerCase()
                              .contains(_searchTerm))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_off_outlined,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            _searchTerm.isNotEmpty
                                ? 'No collections match "$_searchTerm"'
                                : 'No collections found',
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(
                        rommCollectionsProvider(widget.instance)),
                    color: AppColors.tealPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) => _CollectionTile(
                        collection: filtered[i],
                        instance: widget.instance,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (!_showVirtual)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'create_collection_fab',
              backgroundColor: AppColors.tealPrimary,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.add),
              label: const Text('New Collection'),
              onPressed: () => _showCreateDialog(api),
            ),
          ),
      ],
    );
  }
}

// ── Auto (virtual) collections ────────────────────────────────────────────────

class _VirtualCollectionsList extends ConsumerWidget {
  const _VirtualCollectionsList({
    required this.instance,
    required this.type,
    required this.searchTerm,
  });

  final Instance instance;
  final String type;
  final String searchTerm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final virtualAsync = ref
        .watch(rommVirtualCollectionsProvider((instance: instance, type: type)));

    return virtualAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(rommVirtualCollectionsProvider(
                  (instance: instance, type: type))),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (virtuals) {
        final filtered = searchTerm.isEmpty
            ? virtuals
            : virtuals
                .where((v) => v.name.toLowerCase().contains(searchTerm))
                .toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No auto collections found'));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final virtual = filtered[i];
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tealPrimary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_outlined,
                    color: AppColors.tealPrimary, size: 20),
              ),
              title: Text(virtual.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${virtual.romCount} ROMs',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RommVirtualCollectionScreen(
                    instance: instance,
                    collection: virtual,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile(
      {required this.collection, required this.instance});
  final RommCollection collection;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.tealPrimary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.folder_outlined,
            color: AppColors.tealPrimary, size: 22),
      ),
      title: Text(
        collection.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${collection.romCount} ROMs',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RommCollectionScreen(
            instance: instance,
            collection: collection,
          ),
        ),
      ),
    );
  }
}

// ── Platform card (grid) — unchanged ─────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  const _PlatformCard(
      {required this.platform, required this.instance, required this.api});
  final RommPlatform platform;
  final Instance instance;
  final RommApi api;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final githubSvgUrl =
        'https://raw.githubusercontent.com/rommapp/romm/master/frontend/assets/platforms/${platform.slug}.svg';
    final rawLogoUrl = platform.urlLogo;
    String? fallbackUrl;
    Map<String, String>? fallbackHeaders;
    if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
      final isExternal = rawLogoUrl.startsWith('http');
      fallbackUrl =
          isExternal ? rawLogoUrl : '${instance.baseUrl}$rawLogoUrl';
      if (!isExternal) {
        final encoded = base64.encode(utf8.encode(instance.apiKey));
        fallbackHeaders = {'Authorization': 'Basic $encoded'};
      }
    }

    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RommPlatformScreen(instance: instance, platform: platform),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _PlatformLogo(
                  slug: platform.slug,
                  githubSvgUrl: githubSvgUrl,
                  fallbackUrl: fallbackUrl,
                  fallbackHeaders: fallbackHeaders,
                  platformName: platform.displayName,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    platform.displayName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${platform.romCount} ROMs',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Platform logo with fallback chain ────────────────────────────────────────

class _PlatformLogo extends StatefulWidget {
  const _PlatformLogo({
    required this.slug,
    required this.githubSvgUrl,
    required this.platformName,
    this.fallbackUrl,
    this.fallbackHeaders,
  });

  final String slug;
  final String githubSvgUrl;
  final String? fallbackUrl;
  final Map<String, String>? fallbackHeaders;
  final String platformName;

  @override
  State<_PlatformLogo> createState() => _PlatformLogoState();
}

class _PlatformLogoState extends State<_PlatformLogo> {
  late final Future<Uint8List?> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _loadSvg();
  }

  Future<Uint8List?> _loadSvg() async {
    if (widget.slug.isNotEmpty) {
      try {
        final data =
            await rootBundle.load('assets/platforms/${widget.slug}.svg');
        return data.buffer.asUint8List();
      } catch (_) {}
    }
    return _fetchSvgBytes(widget.githubSvgUrl);
  }

  static Future<Uint8List?> _fetchSvgBytes(String url) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        client.close(force: true);
        return null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      client.close();
      return builder.takeBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _svgFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.expand();
        }
        final bytes = snap.data;
        if (bytes != null) {
          return SvgPicture.memory(bytes, fit: BoxFit.contain);
        }
        if (widget.fallbackUrl != null) {
          return Image.network(
            widget.fallbackUrl!,
            fit: BoxFit.contain,
            headers: widget.fallbackHeaders,
            errorBuilder: (_, _, _) => _LetterBadge(widget.platformName),
          );
        }
        return _LetterBadge(widget.platformName);
      },
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.tealPrimary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

// ── Active filter chips ───────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filters, required this.onClear});
  final RommSearchFilters filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final allFilters = [
      if (filters.favourite == true) 'Favorites',
      if (filters.matched == true) 'Matched',
      if (filters.duplicate == true) 'Duplicates',
      if (filters.playable == true) 'Playable',
      if (filters.missing == true) 'Missing',
      ...filters.genres,
      ...filters.franchises,
      ...filters.companies,
      ...filters.ageRatings,
      ...filters.regions,
      ...filters.languages,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: allFilters
                  .take(4)
                  .map((f) => Chip(
                        label: Text(f,
                            style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Clear',
                style: TextStyle(color: AppColors.tealPrimary)),
          ),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.available});
  final RommSearchFilters current;
  final RommAvailableFilters available;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

/// On/off chip for boolean ROM filters (null = inactive, true = required).
class _QuickToggleChip extends StatelessWidget {
  const _QuickToggleChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = value == true;
    return FilterChip(
      avatar: Icon(icon,
          size: 16,
          color: active ? Colors.white : AppColors.tealPrimary),
      label: Text(label),
      selected: active,
      showCheckmark: false,
      selectedColor: AppColors.tealPrimary,
      labelStyle: TextStyle(
        fontSize: 12,
        color: active
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
      ),
      onSelected: (selected) => onChanged(selected ? true : null),
    );
  }
}

class _FilterSheetState extends State<_FilterSheet> {
  late RommSearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.current;
  }

  void _toggle(String value, List<String> current,
      RommSearchFilters Function(List<String>) update) {
    final updated = List<String>.from(current);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    setState(() => _filters = update(updated));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noFiltersFromServer = widget.available.isEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Text('Filters',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_filters.hasActiveFilters)
                    TextButton(
                      onPressed: () => setState(
                          () => _filters = const RommSearchFilters()),
                      child: const Text('Clear all'),
                    ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, _filters),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                      controller: controller,
                      children: [
                        // Quick toggles — always available, no server options
                        // required.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            'Quick filters',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _QuickToggleChip(
                                label: 'Favorites',
                                icon: Icons.favorite_outline,
                                value: _filters.favourite,
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(favourite: v)),
                              ),
                              _QuickToggleChip(
                                label: 'Matched',
                                icon: Icons.verified_outlined,
                                value: _filters.matched,
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(matched: v)),
                              ),
                              _QuickToggleChip(
                                label: 'Duplicates',
                                icon: Icons.copy_outlined,
                                value: _filters.duplicate,
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(duplicate: v)),
                              ),
                              _QuickToggleChip(
                                label: 'Playable',
                                icon: Icons.play_circle_outline,
                                value: _filters.playable,
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(playable: v)),
                              ),
                              _QuickToggleChip(
                                label: 'Missing',
                                icon: Icons.help_outline,
                                value: _filters.missing,
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(missing: v)),
                              ),
                            ],
                          ),
                        ),
                        if (noFiltersFromServer)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No metadata filter options available from '
                              'server.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (widget.available.genres.isNotEmpty)
                          _FilterCategory(
                            title: 'Genres',
                            options: widget.available.genres,
                            selected: _filters.genres,
                            onToggle: (v) => _toggle(v, _filters.genres,
                                (l) => _filters.copyWith(genres: l)),
                          ),
                        if (widget.available.franchises.isNotEmpty)
                          _FilterCategory(
                            title: 'Franchises',
                            options: widget.available.franchises,
                            selected: _filters.franchises,
                            onToggle: (v) => _toggle(
                                v,
                                _filters.franchises,
                                (l) =>
                                    _filters.copyWith(franchises: l)),
                          ),
                        if (widget.available.companies.isNotEmpty)
                          _FilterCategory(
                            title: 'Companies',
                            options: widget.available.companies,
                            selected: _filters.companies,
                            onToggle: (v) => _toggle(
                                v,
                                _filters.companies,
                                (l) =>
                                    _filters.copyWith(companies: l)),
                          ),
                        if (widget.available.ageRatings.isNotEmpty)
                          _FilterCategory(
                            title: 'Age Ratings',
                            options: widget.available.ageRatings,
                            selected: _filters.ageRatings,
                            onToggle: (v) => _toggle(
                                v,
                                _filters.ageRatings,
                                (l) =>
                                    _filters.copyWith(ageRatings: l)),
                          ),
                        if (widget.available.regions.isNotEmpty)
                          _FilterCategory(
                            title: 'Regions',
                            options: widget.available.regions,
                            selected: _filters.regions,
                            onToggle: (v) => _toggle(v, _filters.regions,
                                (l) => _filters.copyWith(regions: l)),
                          ),
                        if (widget.available.languages.isNotEmpty)
                          _FilterCategory(
                            title: 'Languages',
                            options: widget.available.languages,
                            selected: _filters.languages,
                            onToggle: (v) => _toggle(
                                v,
                                _filters.languages,
                                (l) =>
                                    _filters.copyWith(languages: l)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCategory extends StatelessWidget {
  const _FilterCategory({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });
  final String title;
  final List<String> options;
  final List<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final selectedCount = options.where(selected.contains).length;
    return ExpansionTile(
      title: Text(title),
      trailing: selectedCount > 0
          ? Chip(
              label: Text('$selectedCount',
                  style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )
          : const Icon(Icons.expand_more),
      children: options
          .map((opt) => CheckboxListTile(
                title: Text(opt),
                value: selected.contains(opt),
                dense: true,
                onChanged: (_) => onToggle(opt),
                activeColor: AppColors.tealPrimary,
              ))
          .toList(),
    );
  }
}
