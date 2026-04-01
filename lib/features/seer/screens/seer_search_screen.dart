import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/search_result.dart';
import '../providers/seer_providers.dart';
import '../widgets/media_card.dart';
import '../widgets/media_tile.dart';
import 'seer_media_detail_screen.dart';

class SeerSearchScreen extends ConsumerStatefulWidget {
  const SeerSearchScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SeerSearchScreen> createState() => _SeerSearchScreenState();
}

class _SeerSearchScreenState extends ConsumerState<SeerSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openDetail(SeerSearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeerMediaDetailScreen(
          instance: widget.instance,
          tmdbId: result.id,
          mediaType: result.mediaType,
          initialTitle: result.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(
      seerSearchProvider((instance: widget.instance, query: _query)),
    );
    final displayMode =
        ref.watch(seerDisplayModeProvider(widget.instance.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.s12),
          child: SearchBar(
            controller: _controller,
            hintText: 'Search movies & shows…',
            leading: const Icon(Icons.search, size: 20),
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12)),
            trailing: _query.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    )
                  ]
                : null,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                setState(() => _query = v.trim());
              });
            },
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? Center(
                  child: Text(
                    'Type to search…',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                )
              : searchAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(
                    child: Text(
                      'Search failed: $e',
                      style:
                          const TextStyle(color: AppColors.statusOffline),
                    ),
                  ),
                  data: (results) {
                    if (results.isEmpty) {
                      return Center(
                        child: Text(
                          'No results for "$_query"',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return displayMode == DisplayMode.grid
                        ? _SearchGrid(
                            results: results,
                            onTap: _openDetail,
                          )
                        : _SearchList(
                            results: results,
                            onTap: _openDetail,
                          );
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchGrid extends StatelessWidget {
  const _SearchGrid({required this.results, required this.onTap});
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

class _SearchList extends StatelessWidget {
  const _SearchList({required this.results, required this.onTap});
  final List<SeerSearchResult> results;
  final void Function(SeerSearchResult) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: results.length,
      separatorBuilder: (_, i) => const Divider(height: 1),
      itemBuilder: (ctx, i) => MediaTile(
        result: results[i],
        onTap: () => onTap(results[i]),
      ),
    );
  }
}
