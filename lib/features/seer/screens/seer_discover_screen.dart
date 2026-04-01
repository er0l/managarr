import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/search_result.dart';
import '../providers/seer_providers.dart';
import '../widgets/media_card.dart';
import 'seer_media_detail_screen.dart';

class SeerDiscoverScreen extends ConsumerStatefulWidget {
  const SeerDiscoverScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SeerDiscoverScreen> createState() =>
      _SeerDiscoverScreenState();
}

class _SeerDiscoverScreenState extends ConsumerState<SeerDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayMode =
        ref.watch(seerDisplayModeProvider(widget.instance.id));

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DiscoverView(
                instance: widget.instance,
                provider: seerDiscoverMoviesProvider,
                displayMode: displayMode,
              ),
              _DiscoverView(
                instance: widget.instance,
                provider: seerDiscoverTvProvider,
                displayMode: displayMode,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscoverView extends ConsumerWidget {
  const _DiscoverView({
    required this.instance,
    required this.provider,
    required this.displayMode,
  });

  final Instance instance;
  final AutoDisposeFutureProviderFamily<List<SeerSearchResult>, Instance>
      provider;
  final DisplayMode displayMode;

  void _openDetail(BuildContext context, SeerSearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeerMediaDetailScreen(
          instance: instance,
          tmdbId: result.id,
          mediaType: result.mediaType,
          initialTitle: result.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider(instance));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            const Text('Failed to load'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(provider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const Center(child: Text('Nothing to show'));
        }
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async => ref.invalidate(provider(instance)),
          child: displayMode == DisplayMode.grid
              ? _DiscoverGrid(
                  results: results,
                  onTap: (r) => _openDetail(context, r),
                )
              : _DiscoverList(
                  results: results,
                  onTap: (r) => _openDetail(context, r),
                ),
        );
      },
    );
  }
}

class _DiscoverGrid extends StatelessWidget {
  const _DiscoverGrid({required this.results, required this.onTap});
  final List<SeerSearchResult> results;
  final void Function(SeerSearchResult) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.s8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width >= 600 ? 3 : 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: Spacing.s8,
        mainAxisSpacing: Spacing.s8,
      ),
      itemCount: results.length,
      itemBuilder: (ctx, i) => MediaCard(
        result: results[i],
        onTap: () => onTap(results[i]),
      ),
    );
  }
}

class _DiscoverList extends StatelessWidget {
  const _DiscoverList({required this.results, required this.onTap});
  final List<SeerSearchResult> results;
  final void Function(SeerSearchResult) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: results.length,
      separatorBuilder: (_, i) => const Divider(height: 1),
      itemBuilder: (ctx, i) => _MediaTile(
        result: results[i],
        onTap: () => onTap(results[i]),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.result, required this.onTap});
  final SeerSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = result.posterUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageHorizontal,
        vertical: 4,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 64,
          child: posterUrl != null
              ? Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, s) => Container(
                    color: AppColors.tealDark,
                    alignment: Alignment.center,
                    child: Icon(
                      result.mediaType == 'movie'
                          ? Icons.movie_outlined
                          : Icons.tv_outlined,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ),
                )
              : Container(
                  color: AppColors.tealDark,
                  alignment: Alignment.center,
                  child: Icon(
                    result.mediaType == 'movie'
                        ? Icons.movie_outlined
                        : Icons.tv_outlined,
                    color: Colors.white24,
                    size: 24,
                  ),
                ),
        ),
      ),
      title: Text(
        result.title,
        style:
            theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (result.year.isNotEmpty) result.year,
          result.mediaType == 'movie' ? 'Movie' : 'TV Show',
        ].join(' · '),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}
