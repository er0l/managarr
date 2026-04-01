import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/media_request.dart';
import '../providers/seer_providers.dart';
import '../widgets/media_request_tile.dart';
import 'seer_media_detail_screen.dart';

class SeerRequestsScreen extends ConsumerStatefulWidget {
  const SeerRequestsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SeerRequestsScreen> createState() => _SeerRequestsScreenState();
}

class _SeerRequestsScreenState extends ConsumerState<SeerRequestsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text =
          ref.read(seerRequestsSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, SeerMediaRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeerMediaDetailScreen(
          instance: widget.instance,
          tmdbId: request.tmdbId,
          mediaType: request.mediaType,
          initialTitle: request.title,
        ),
      ),
    );
  }

  void _showSortSheet() {
    final current = ref.read(seerRequestsSortProvider(widget.instance.id));
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Sort by',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            ...SeerRequestSort.values.map((s) => ListTile(
                  title: Text(s.label),
                  trailing: current == s
                      ? const Icon(Icons.check, color: AppColors.tealPrimary)
                      : null,
                  onTap: () {
                    ref
                        .read(seerRequestsSortProvider(widget.instance.id)
                            .notifier)
                        .state = s;
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final current =
        ref.read(seerRequestsStatusFilterProvider(widget.instance.id));
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Filter by Status',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            ...SeerRequestStatusFilter.values.map((f) => ListTile(
                  title: Text(f.label),
                  trailing: current == f
                      ? const Icon(Icons.check, color: AppColors.tealPrimary)
                      : null,
                  onTap: () {
                    ref
                        .read(seerRequestsStatusFilterProvider(
                                widget.instance.id)
                            .notifier)
                        .state = f;
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(seerRequestsProvider(widget.instance));
    final filtered = ref.watch(seerFilteredRequestsProvider(widget.instance));
    final displayMode = ref.watch(seerDisplayModeProvider(widget.instance.id));
    final query =
        ref.watch(seerRequestsSearchQueryProvider(widget.instance.id));
    final currentSort =
        ref.watch(seerRequestsSortProvider(widget.instance.id));
    final currentFilter =
        ref.watch(seerRequestsStatusFilterProvider(widget.instance.id));

    return Column(
      children: [
        // Search + controls bar
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
                    hintText: 'Search requests…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(seerRequestsSearchQueryProvider(
                                          widget.instance.id)
                                      .notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => ref
                      .read(seerRequestsSearchQueryProvider(widget.instance.id)
                          .notifier)
                      .state = v,
                ),
              ),
              const SizedBox(width: Spacing.s8),
              _ControlButton(
                icon: Icons.filter_list,
                isActive: currentFilter != SeerRequestStatusFilter.all,
                onTap: _showFilterSheet,
              ),
              const SizedBox(width: Spacing.s4),
              _ControlButton(
                icon: Icons.sort,
                isActive: currentSort != SeerRequestSort.newest,
                onTap: _showSortSheet,
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: requestsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.statusOffline),
                  const SizedBox(height: 12),
                  Text('Failed to load requests',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(seerRequestsProvider(widget.instance)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (_) {
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    query.isNotEmpty
                        ? 'No results for "$query"'
                        : 'No requests found',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.tealPrimary,
                onRefresh: () async =>
                    ref.invalidate(seerRequestsProvider(widget.instance)),
                child: displayMode == DisplayMode.grid
                    ? _RequestsGrid(
                        requests: filtered,
                        onTap: (r) => _openDetail(context, r),
                      )
                    : _RequestsList(
                        requests: filtered,
                        onTap: (r) => _openDetail(context, r),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton(
      {required this.icon, required this.isActive, required this.onTap});
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
        backgroundColor:
            isActive ? colorScheme.primaryContainer : null,
        foregroundColor:
            isActive ? colorScheme.onPrimaryContainer : null,
      ),
      icon: Icon(icon),
    );
  }
}

class _RequestsGrid extends StatelessWidget {
  const _RequestsGrid({required this.requests, required this.onTap});
  final List<SeerMediaRequest> requests;
  final void Function(SeerMediaRequest) onTap;

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
      itemCount: requests.length,
      itemBuilder: (ctx, i) =>
          _RequestGridCard(request: requests[i], onTap: () => onTap(requests[i])),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.requests, required this.onTap});
  final List<SeerMediaRequest> requests;
  final void Function(SeerMediaRequest) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: requests.length,
      separatorBuilder: (_, i) => const Divider(height: 1),
      itemBuilder: (ctx, i) => MediaRequestTile(
        request: requests[i],
        onTap: () => onTap(requests[i]),
      ),
    );
  }
}

class _RequestGridCard extends StatelessWidget {
  const _RequestGridCard({required this.request, required this.onTap});
  final SeerMediaRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = request.posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w342${request.posterPath}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (posterUrl != null)
              Image.network(
                posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (e, s, t) => _Placeholder(request: request),
              )
            else
              _Placeholder(request: request),
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
                      request.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: request.statusColor.withAlpha(200),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        request.statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.request});
  final SeerMediaRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: Icon(
        request.mediaType == 'movie'
            ? Icons.movie_outlined
            : Icons.tv_outlined,
        color: Colors.white24,
        size: 40,
      ),
    );
  }
}
