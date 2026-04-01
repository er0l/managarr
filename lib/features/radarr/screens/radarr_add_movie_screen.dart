import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';
import 'radarr_add_movie_detail_screen.dart';
import 'radarr_movie_detail_screen.dart';

class RadarrAddMovieScreen extends ConsumerStatefulWidget {
  const RadarrAddMovieScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<RadarrAddMovieScreen> createState() =>
      _RadarrAddMovieScreenState();
}

class _RadarrAddMovieScreenState extends ConsumerState<RadarrAddMovieScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(radarrLookupQueryProvider(widget.instance.id).notifier).state =
          value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(radarrLookupResultsProvider(widget.instance));
    final query = ref.watch(radarrLookupQueryProvider(widget.instance.id));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textOnPrimary),
          cursorColor: AppColors.orangeAccent,
          decoration: const InputDecoration(
            hintText: 'Search for a movie…',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textOnPrimary),
              onPressed: () {
                _searchController.clear();
                ref
                    .read(
                        radarrLookupQueryProvider(widget.instance.id).notifier)
                    .state = '';
              },
            ),
        ],
      ),
      body: query.trim().isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.movie_filter_outlined,
                      size: 64, color: AppColors.textSecondary.withAlpha(80)),
                  const SizedBox(height: Spacing.s16),
                  Text(
                    'Search for a movie to add',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.s32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off,
                          size: 48, color: AppColors.statusOffline),
                      const SizedBox(height: Spacing.s16),
                      Text('Search failed',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: Spacing.s8),
                      Text(
                        e.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              data: (movies) {
                if (movies.isEmpty) {
                  return Center(
                    child: Text(
                      'No results for "$query"',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(
                      top: Spacing.s8, bottom: Spacing.s24),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    final alreadyAdded = movie.id > 0;
                    return _SearchResultTile(
                      movie: movie,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => alreadyAdded
                              ? RadarrMovieDetailScreen(
                                  movie: movie,
                                  instance: widget.instance,
                                )
                              : RadarrAddMovieDetailScreen(
                                  movie: movie,
                                  instance: widget.instance,
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.movie, required this.onTap});
  final RadarrMovie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = movie.posterUrl;
    final alreadyAdded = movie.id > 0;

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
              ? Image.network(posterUrl, fit: BoxFit.cover)
              : Container(
                  color: AppColors.tealDark,
                  alignment: Alignment.center,
                  child: Text(
                    movie.title.isNotEmpty ? movie.title[0] : 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(
        movie.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          '${movie.year}',
          if (movie.studio != null) movie.studio,
        ].join(' · '),
        style:
            theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: alreadyAdded
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: const Text('In Library'),
                  labelStyle: const TextStyle(
                      fontSize: 11,
                      color: AppColors.statusOnline,
                      fontWeight: FontWeight.w500),
                  backgroundColor: AppColors.statusOnline.withAlpha(20),
                  side: BorderSide(color: AppColors.statusOnline.withAlpha(60)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
