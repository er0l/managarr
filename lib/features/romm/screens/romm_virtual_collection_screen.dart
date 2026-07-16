import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/providers/ui_prefs_provider.dart';
import '../api/models/romm_rom.dart';
import '../api/models/romm_virtual_collection.dart';
import '../providers/romm_providers.dart';
import 'romm_rom_detail_screen.dart';

/// Browse the ROMs of an auto-generated (virtual) collection.
class RommVirtualCollectionScreen extends ConsumerStatefulWidget {
  const RommVirtualCollectionScreen({
    super.key,
    required this.instance,
    required this.collection,
  });

  final Instance instance;
  final RommVirtualCollection collection;

  @override
  ConsumerState<RommVirtualCollectionScreen> createState() =>
      _RommVirtualCollectionScreenState();
}

class _RommVirtualCollectionScreenState
    extends ConsumerState<RommVirtualCollectionScreen> {
  final _scrollController = ScrollController();

  final List<RommRom> _roms = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadPage(reset: false);
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    final api = ref.read(rommApiProvider(widget.instance));
    setState(() {
      if (reset) {
        _roms.clear();
        _offset = 0;
        _hasMore = true;
        _error = null;
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });
    try {
      final page = await api.getVirtualCollectionRoms(
        widget.collection.id,
        limit: _pageSize,
        offset: _offset,
        orderBy: 'name',
        orderDir: 'asc',
      );
      if (!mounted) return;
      setState(() {
        _roms.addAll(page);
        _offset += page.length;
        _hasMore = page.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (reset) _error = '$e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(rommApiProvider(widget.instance));
    final columns = ref.watch(gridColumnsProvider) +
        (MediaQuery.sizeOf(context).width >= 600 ? 1 : 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.collection.name,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text(
              '${widget.collection.romCount} ROMs',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
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
                  Text(_error!, textAlign: TextAlign.center),
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
            return const Center(child: Text('No ROMs found'));
          }
          return RefreshIndicator(
            color: AppColors.tealPrimary,
            onRefresh: () => _loadPage(reset: true),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemCount: _roms.length + (_isLoadingMore ? columns : 0),
              itemBuilder: (ctx, i) {
                if (i >= _roms.length) {
                  return const Card(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final rom = _roms[i];
                final coverUrl = api.coverUrl(rom);
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RommRomDetailScreen(
                          instance: widget.instance,
                          romId: rom.id,
                          romName: rom.name,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: coverUrl != null
                              ? Image.network(
                                  coverUrl,
                                  fit: BoxFit.cover,
                                  headers: coverUrl.startsWith(api.baseUrl)
                                      ? {'Authorization': api.authHeader}
                                      : null,
                                  errorBuilder: (_, _, _) =>
                                      const _CoverFallback(),
                                )
                              : const _CoverFallback(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rom.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                rom.platformDisplayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 9,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.videogame_asset_outlined,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }
}
