import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/romm_platform.dart';
import '../api/models/romm_rom.dart';
import '../api/romm_api.dart';
import '../providers/romm_providers.dart';
import 'romm_rom_detail_screen.dart';

class RommPlatformScreen extends ConsumerStatefulWidget {
  const RommPlatformScreen({
    super.key,
    required this.instance,
    required this.platform,
  });

  final Instance instance;
  final RommPlatform platform;

  @override
  ConsumerState<RommPlatformScreen> createState() => _RommPlatformScreenState();
}

class _RommPlatformScreenState extends ConsumerState<RommPlatformScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  RommRomsKey get _key => (
        instance: widget.instance,
        platformId: widget.platform.id,
        searchTerm: _searchTerm,
      );

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchTerm = '');
  }

  @override
  Widget build(BuildContext context) {
    final romsAsync = ref.watch(rommRomsProvider(_key));
    final api = ref.watch(rommApiProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Text(
          widget.platform.displayName,
          style: const TextStyle(color: AppColors.textOnPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: () => ref.invalidate(rommRomsProvider(_key)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ROMs…',
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
              onChanged: (v) => setState(() => _searchTerm = v.trim()),
            ),
          ),
          // Results
          Expanded(
            child: romsAsync.when(
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
                      onPressed: () =>
                          ref.invalidate(rommRomsProvider(_key)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (roms) {
                if (roms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_outlined,
                            size: 48,
                            color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _searchTerm.isNotEmpty
                              ? 'No ROMs found for "$_searchTerm"'
                              : 'No ROMs in this platform',
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(rommRomsProvider(_key)),
                  color: AppColors.tealPrimary,
                  child: ListView.separated(
                    itemCount: roms.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) => _RomTile(
                      rom: roms[i],
                      api: api,
                      instance: widget.instance,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ROM list tile
// ---------------------------------------------------------------------------

class _RomTile extends StatelessWidget {
  const _RomTile({
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
        errorBuilder: (_, _, _) => _coverPlaceholder(),
      );
    } else {
      cover = _coverPlaceholder();
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
          if (rom.releaseYear != null) rom.releaseYear.toString(),
          if (rom.formattedSize.isNotEmpty) rom.formattedSize,
          if (rom.averageRating != null && rom.averageRating! > 0)
            '★ ${rom.averageRating!.toStringAsFixed(1)}',
        ].join(' · '),
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

  Widget _coverPlaceholder() {
    return Container(
      color: AppColors.tealPrimary.withAlpha(20),
      child: const Icon(Icons.videogame_asset_outlined,
          color: AppColors.tealPrimary, size: 24),
    );
  }
}
