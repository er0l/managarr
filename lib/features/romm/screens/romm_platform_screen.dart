import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/romm_platform.dart';
import '../api/models/romm_rom.dart';
import '../api/romm_api.dart';
import '../providers/romm_providers.dart';
import 'romm_rom_detail_screen.dart';

enum _ViewMode { list, grid }

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
  static const _pageSize = 50;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  String _searchTerm = '';
  _ViewMode _viewMode = _ViewMode.list;

  List<RommRom> _roms = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoading) return;
    if (mounted) {
      setState(() {
        if (reset) {
          _roms = [];
          _offset = 0;
          _hasMore = true;
          _error = null;
        }
        _isLoading = true;
      });
    }
    try {
      final api = ref.read(rommApiProvider(widget.instance));
      final results = await api.getRoms(
        widget.platform.id,
        searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
        limit: _pageSize,
        offset: reset ? 0 : _offset,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _roms = results;
          } else {
            _roms = [..._roms, ...results];
          }
          _offset = (reset ? 0 : _offset) + results.length;
          _hasMore = results.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      final api = ref.read(rommApiProvider(widget.instance));
      final results = await api.getRoms(
        widget.platform.id,
        searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
        limit: _pageSize,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _roms = [..._roms, ...results];
          _offset += results.length;
          _hasMore = results.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String v) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final term = v.trim();
      if (term != _searchTerm) {
        setState(() => _searchTerm = term);
        _loadPage(reset: true);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    if (_searchTerm.isNotEmpty) {
      setState(() => _searchTerm = '');
      _loadPage(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(rommApiProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.platform.displayName,
                style: const TextStyle(
                    color: AppColors.textOnPrimary, fontSize: 16)),
            if (_roms.isNotEmpty)
              Text(
                '${_roms.length}${_hasMore ? '+' : ''} ROMs',
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == _ViewMode.list
                  ? Icons.grid_view_outlined
                  : Icons.list_outlined,
              color: AppColors.textOnPrimary,
            ),
            tooltip:
                _viewMode == _ViewMode.list ? 'Grid view' : 'List view',
            onPressed: () => setState(() => _viewMode =
                _viewMode == _ViewMode.list
                    ? _ViewMode.grid
                    : _ViewMode.list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: () => _loadPage(reset: true),
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
              onChanged: _onSearchChanged,
            ),
          ),
          // Results
          Expanded(child: _buildBody(api)),
        ],
      ),
    );
  }

  Widget _buildBody(RommApi api) {
    if (_isLoading && _roms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _roms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadPage(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_roms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined,
                size: 48, color: AppColors.textSecondary),
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
      onRefresh: () => _loadPage(reset: true),
      color: AppColors.tealPrimary,
      child: _viewMode == _ViewMode.list
          ? _buildListView(api)
          : _buildGridView(api),
    );
  }

  Widget _buildListView(RommApi api) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: _roms.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        if (i == _roms.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _RomListTile(
          rom: _roms[i],
          api: api,
          instance: widget.instance,
        );
      },
    );
  }

  Widget _buildGridView(RommApi api) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemCount: _roms.length + (_isLoadingMore ? 3 : 0),
      itemBuilder: (ctx, i) {
        if (i >= _roms.length) {
          return const Card(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _RomGridCard(
          rom: _roms[i],
          api: api,
          instance: widget.instance,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// ROM list tile
// ---------------------------------------------------------------------------

class _RomListTile extends StatelessWidget {
  const _RomListTile({
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

  Widget _placeholder() {
    return Container(
      color: AppColors.tealPrimary.withAlpha(20),
      child: const Icon(Icons.videogame_asset_outlined,
          color: AppColors.tealPrimary, size: 24),
    );
  }
}

// ---------------------------------------------------------------------------
// ROM grid card
// ---------------------------------------------------------------------------

class _RomGridCard extends StatelessWidget {
  const _RomGridCard({
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
        fit: BoxFit.cover,
        headers: isExternal ? null : {'Authorization': api.authHeader},
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      cover = _placeholder();
    }

    return GestureDetector(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rom.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600),
          ),
          if (rom.releaseYear != null)
            Text(
              '${rom.releaseYear}',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.tealPrimary.withAlpha(20),
      child: const Center(
        child: Icon(Icons.videogame_asset_outlined,
            color: AppColors.tealPrimary, size: 32),
      ),
    );
  }
}
