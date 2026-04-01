import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/artist.dart';
import '../providers/lidarr_providers.dart';
import 'lidarr_add_artist_detail_screen.dart';

class LidarrAddArtistScreen extends ConsumerStatefulWidget {
  const LidarrAddArtistScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<LidarrAddArtistScreen> createState() =>
      _LidarrAddArtistScreenState();
}

class _LidarrAddArtistScreenState
    extends ConsumerState<LidarrAddArtistScreen> {
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
      ref
          .read(lidarrLookupQueryProvider(widget.instance.id).notifier)
          .state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync =
        ref.watch(lidarrLookupResultsProvider(widget.instance));
    final existingAsync = ref.watch(lidarrArtistsProvider(widget.instance));
    final existingIds = existingAsync.maybeWhen(
      data: (artists) =>
          artists.map((a) => a.foreignArtistId).toSet(),
      orElse: () => <String?>{},
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text(
          'Add Artist',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.pageHorizontal,
              Spacing.s12,
              Spacing.pageHorizontal,
              Spacing.s8,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for an artist…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(lidarrLookupQueryProvider(
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
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Search failed: $e',
                  style: const TextStyle(color: AppColors.statusOffline),
                ),
              ),
              data: (results) {
                if (_searchController.text.isEmpty) {
                  return Center(
                    child: Text(
                      'Search for an artist to add',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: Spacing.s24),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final artist = results[index];
                    final inLibrary =
                        existingIds.contains(artist.foreignArtistId);
                    return _ArtistResultTile(
                      artist: artist,
                      inLibrary: inLibrary,
                      onTap: inLibrary
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LidarrAddArtistDetailScreen(
                                    artist: artist,
                                    instance: widget.instance,
                                  ),
                                ),
                              ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistResultTile extends StatelessWidget {
  const _ArtistResultTile({
    required this.artist,
    required this.inLibrary,
    required this.onTap,
  });

  final LidarrArtist artist;
  final bool inLibrary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = artist.posterUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageHorizontal,
        vertical: 4,
      ),
      onTap: onTap,
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
                    artist.artistName.isNotEmpty
                        ? artist.artistName[0]
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(
        artist.artistName,
        style: theme.textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (artist.artistType != null)
            Text(
              artist.artistType!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          if (inLibrary) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.tealPrimary.withAlpha(80)),
              ),
              child: const Text(
                'In Library',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.tealPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: inLibrary
          ? null
          : const Icon(Icons.chevron_right,
              color: AppColors.textSecondary),
    );
  }
}
