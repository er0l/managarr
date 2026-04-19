import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../api/models/romm_available_filters.dart';
import '../api/models/romm_collection.dart';
import '../api/models/romm_platform.dart';
import '../api/models/romm_rom.dart';
import '../api/models/romm_search_filters.dart';
import '../api/models/romm_stats.dart';
import '../api/romm_api.dart';
import '../providers/romm_providers.dart';
import 'romm_collection_screen.dart';
import 'romm_platform_screen.dart';
import 'romm_rom_detail_screen.dart';

class RommHomeScreen extends StatefulWidget {
  const RommHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<RommHomeScreen> createState() => _RommHomeScreenState();
}

class _RommHomeScreenState extends State<RommHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Platforms', 'Collections', 'Search'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'ROMM',
      tabs: _tabs,
      tabController: _tabController,
      tabViews: [
        _PlatformsTab(instance: widget.instance),
        _CollectionsTab(instance: widget.instance),
        _SearchTab(instance: widget.instance),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Platforms tab
// ---------------------------------------------------------------------------

class _PlatformsTab extends ConsumerWidget {
  const _PlatformsTab({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformsAsync = ref.watch(rommPlatformsProvider(instance));
    final statsAsync = ref.watch(rommStatsProvider(instance));
    final api = ref.watch(rommApiProvider(instance));
    final theme = Theme.of(context);

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
        if (platforms.isEmpty) {
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
        return Column(
          children: [
            // Stats card
            statsAsync.maybeWhen(
              data: (stats) => _StatsCard(
                stats: stats,
                theme: theme,
                onRescan: () async {
                  try {
                    await api.scanLibrary();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Library scan started'),
                          backgroundColor: AppColors.statusOnline,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Scan failed: $e'),
                          backgroundColor: AppColors.statusOffline,
                        ),
                      );
                    }
                  }
                },
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(rommPlatformsProvider(instance));
                  ref.invalidate(rommStatsProvider(instance));
                },
                color: AppColors.tealPrimary,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: platforms.length,
                  itemBuilder: (ctx, i) => _PlatformCard(
                    platform: platforms[i],
                    instance: instance,
                    api: api,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.stats,
    required this.theme,
    required this.onRescan,
  });

  final RommStats stats;
  final ThemeData theme;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final parts = [
      '${stats.totalRoms} ROMs',
      '${stats.totalPlatforms} platforms',
      if (stats.formattedSize.isNotEmpty) stats.formattedSize,
    ];
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.storage_outlined,
                size: 18, color: AppColors.tealPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parts.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Rescan'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.instance,
    required this.api,
  });

  final RommPlatform platform;
  final Instance instance;
  final RommApi api;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // GitHub CDN SVG logo (primary) — matches platform slug exactly.
    final githubSvgUrl =
        'https://raw.githubusercontent.com/rommapp/romm/master/frontend/assets/platforms/${platform.slug}.svg';

    // Resolve ROMM/IGDB fallback logo URL and auth header.
    // IGDB logos start with https:// — public, no auth needed.
    // ROMM-hosted logos may be relative paths — need base URL + auth.
    final rawLogoUrl = platform.urlLogo;
    String? fallbackUrl;
    Map<String, String>? fallbackHeaders;
    if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
      final isExternal = rawLogoUrl.startsWith('http');
      fallbackUrl = isExternal ? rawLogoUrl : '${instance.baseUrl}$rawLogoUrl';
      if (!isExternal) {
        final encoded = base64.encode(utf8.encode(instance.apiKey));
        fallbackHeaders = {'Authorization': 'Basic $encoded'};
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            // ── Dark logo header — all platform artwork is designed for
            //    dark backgrounds; this eliminates visible black outlines.
            SizedBox(
              height: 64,
              width: double.infinity,
              child: ColoredBox(
                color: const Color(0xFF12121E),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _PlatformLogo(
                    slug: platform.slug,
                    githubSvgUrl: githubSvgUrl,
                    fallbackUrl: fallbackUrl,
                    fallbackHeaders: fallbackHeaders,
                    platformName: platform.displayName,
                  ),
                ),
              ),
            ),
            // ── Platform name + ROM count ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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

/// Platform logo with a three-tier fallback chain (all rendered on the dark
/// card header — no extra badge needed):
///
///   1. Bundled local asset  assets/platforms/{slug}.svg
///      229 platform SVGs shipped with the app; instant, no network.
///   2. GitHub CDN           rommapp/romm frontend/assets/platforms/{slug}.svg
///      Catches slugs not yet in the bundled set.
///   3. IGDB / ROMM raster   platform.urlLogo (http or relative path + auth)
///   4. _LetterBadge         first letter of the platform name
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

  /// Tries local bundled asset first (fast, cached by rootBundle), then falls
  /// back to a GitHub CDN fetch over the network.
  Future<Uint8List?> _loadSvg() async {
    // ── Tier 1: local bundled asset ──────────────────────────────────────────
    if (widget.slug.isNotEmpty) {
      try {
        final data = await rootBundle
            .load('assets/platforms/${widget.slug}.svg');
        return data.buffer.asUint8List();
      } catch (_) {
        // Asset not bundled for this slug — fall through to network.
      }
    }

    // ── Tier 2: GitHub CDN ───────────────────────────────────────────────────
    return _fetchSvgBytes(widget.githubSvgUrl);
  }

  /// HTTP GET returning raw bytes, or null on any error / non-200 response.
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
          // Still loading — dark header is already visible, nothing to show.
          return const SizedBox.expand();
        }

        final bytes = snap.data;
        if (bytes != null) {
          // Tiers 1–2: SVG bytes available (local or CDN).
          return SvgPicture.memory(bytes, fit: BoxFit.contain);
        }

        // ── Tier 3: IGDB / ROMM raster logo ─────────────────────────────────
        if (widget.fallbackUrl != null) {
          return Image.network(
            widget.fallbackUrl!,
            fit: BoxFit.contain,
            headers: widget.fallbackHeaders,
            errorBuilder: (_, _, _) => _LetterBadge(widget.platformName),
          );
        }

        // ── Tier 4: letter badge ─────────────────────────────────────────────
        return _LetterBadge(widget.platformName);
      },
    );
  }
}

/// Last-resort fallback — shows the first letter of the platform name.
/// Rendered on the dark card header, so teal text on dark looks clean.
class _LetterBadge extends StatelessWidget {
  const _LetterBadge(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.tealPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collections tab
// ---------------------------------------------------------------------------

class _CollectionsTab extends ConsumerStatefulWidget {
  const _CollectionsTab({required this.instance});

  final Instance instance;

  @override
  ConsumerState<_CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends ConsumerState<_CollectionsTab> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateCollectionDialog(
      BuildContext context, RommApi api) async {
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
      await api.createCollection(
          name,
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
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                onChanged: (v) => setState(() => _searchTerm = v.toLowerCase()),
              ),
            ),
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
                        onPressed: () => ref
                            .invalidate(rommCollectionsProvider(widget.instance)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (collections) {
                  final filtered = _searchTerm.isEmpty
                      ? collections
                      : collections
                          .where((c) =>
                              c.name.toLowerCase().contains(_searchTerm))
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
                    onRefresh: () async =>
                        ref.invalidate(rommCollectionsProvider(widget.instance)),
                    color: AppColors.tealPrimary,
                    child: ListView.separated(
                      // Add padding at bottom so FAB doesn't cover last item
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
        // FAB for creating new collection
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'create_collection_fab',
            backgroundColor: AppColors.tealPrimary,
            foregroundColor: AppColors.textOnPrimary,
            icon: const Icon(Icons.add),
            label: const Text('New Collection'),
            onPressed: () => _showCreateCollectionDialog(context, api),
          ),
        ),
      ],
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.collection,
    required this.instance,
  });

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

// ---------------------------------------------------------------------------
// Search tab — global search with filters
// ---------------------------------------------------------------------------

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab({required this.instance});

  final Instance instance;

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  RommSearchFilters _filters = const RommSearchFilters();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  RommSearchKey get _key => (
        instance: widget.instance,
        searchTerm: _searchTerm,
        filters: _filters,
      );

  bool get _shouldSearch =>
      _searchTerm.isNotEmpty || _filters.hasActiveFilters;

  void _onSearchChanged(String v) {
    setState(() {
      _searchTerm = v.trim();
      _hasSearched = _shouldSearch;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchTerm = '';
      _hasSearched = _filters.hasActiveFilters;
    });
  }

  Future<void> _showFilterSheet() async {
    // Await available filters; show snackbar on error but still open sheet
    // so users can clear existing active filters.
    RommAvailableFilters filtersData;
    try {
      filtersData = await ref
          .read(rommAvailableFiltersProvider(widget.instance).future);
    } catch (e) {
      filtersData = const RommAvailableFilters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load filter options: $e'),
          backgroundColor: AppColors.statusOffline,
          duration: const Duration(seconds: 4),
        ));
      }
    }
    if (!mounted) return;

    final updated = await showModalBottomSheet<RommSearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        current: _filters,
        available: filtersData,
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _filters = updated;
        _hasSearched = _shouldSearch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fetch filter options in the background as soon as the Search tab opens.
    ref.watch(rommAvailableFiltersProvider(widget.instance));

    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar + filter button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search all ROMs…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) =>
                      setState(() => _hasSearched = _shouldSearch),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button
              _FilterButton(
                isActive: _filters.hasActiveFilters,
                onTap: _showFilterSheet,
              ),
            ],
          ),
        ),

        // Active filter chips
        if (_filters.hasActiveFilters)
          _ActiveFilterChips(
            filters: _filters,
            onClear: () => setState(() {
              _filters = const RommSearchFilters();
              _hasSearched = _searchTerm.isNotEmpty;
            }),
          ),

        // Results
        Expanded(
          child: !_hasSearched
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search,
                          size: 56, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'Search or apply filters\nto find ROMs',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _SearchResults(
                  searchKey: _key,
                  instance: widget.instance,
                ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? AppColors.tealPrimary.withAlpha(30)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.tune_outlined,
            size: 20,
            color: isActive
                ? AppColors.tealPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filters, required this.onClear});

  final RommSearchFilters filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final allFilters = [
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

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.searchKey,
    required this.instance,
  });

  final RommSearchKey searchKey;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romsAsync = ref.watch(rommSearchProvider(searchKey));
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(rommSearchProvider(searchKey)),
              child: const Text('Retry'),
            ),
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
          itemBuilder: (ctx, i) =>
              _SearchRomTile(rom: roms[i], api: api, instance: instance),
        );
      },
    );
  }
}

class _SearchRomTile extends StatelessWidget {
  const _SearchRomTile({
    required this.rom,
    required this.api,
    required this.instance,
  });

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

  Widget _placeholder() {
    return Container(
      color: AppColors.tealPrimary.withAlpha(20),
      child: const Icon(Icons.videogame_asset_outlined,
          color: AppColors.tealPrimary, size: 24),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.available});

  final RommSearchFilters current;
  final RommAvailableFilters available;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
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
    final hasAnyFilters = widget.available.isEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
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
                    onPressed: () => Navigator.pop(context, _filters),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Filter categories
            Expanded(
              child: hasAnyFilters
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No filter options available from server.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      controller: controller,
                      children: [
                        if (widget.available.genres.isNotEmpty)
                          _FilterCategory(
                            title: 'Genres',
                            options: widget.available.genres,
                            selected: _filters.genres,
                            onToggle: (v) => _toggle(
                              v,
                              _filters.genres,
                              (l) => _filters.copyWith(genres: l),
                            ),
                          ),
                        if (widget.available.franchises.isNotEmpty)
                          _FilterCategory(
                            title: 'Franchises',
                            options: widget.available.franchises,
                            selected: _filters.franchises,
                            onToggle: (v) => _toggle(
                              v,
                              _filters.franchises,
                              (l) => _filters.copyWith(franchises: l),
                            ),
                          ),
                        if (widget.available.companies.isNotEmpty)
                          _FilterCategory(
                            title: 'Companies',
                            options: widget.available.companies,
                            selected: _filters.companies,
                            onToggle: (v) => _toggle(
                              v,
                              _filters.companies,
                              (l) => _filters.copyWith(companies: l),
                            ),
                          ),
                        if (widget.available.ageRatings.isNotEmpty)
                          _FilterCategory(
                            title: 'Age Ratings',
                            options: widget.available.ageRatings,
                            selected: _filters.ageRatings,
                            onToggle: (v) => _toggle(
                              v,
                              _filters.ageRatings,
                              (l) => _filters.copyWith(ageRatings: l),
                            ),
                          ),
                        if (widget.available.regions.isNotEmpty)
                          _FilterCategory(
                            title: 'Regions',
                            options: widget.available.regions,
                            selected: _filters.regions,
                            onToggle: (v) => _toggle(
                              v,
                              _filters.regions,
                              (l) => _filters.copyWith(regions: l),
                            ),
                          ),
                        if (widget.available.languages.isNotEmpty)
                          _FilterCategory(
                            title: 'Languages',
                            options: widget.available.languages,
                            selected: _filters.languages,
                            onToggle: (v) => _toggle(
                              v,
                              _filters.languages,
                              (l) => _filters.copyWith(languages: l),
                            ),
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
