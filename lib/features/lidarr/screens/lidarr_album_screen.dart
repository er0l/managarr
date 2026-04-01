import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/album.dart';
import '../providers/lidarr_providers.dart';
import 'lidarr_album_releases_screen.dart';

class LidarrAlbumScreen extends ConsumerWidget {
  const LidarrAlbumScreen({
    super.key,
    required this.album,
    required this.instance,
    required this.artistName,
  });

  final LidarrAlbum album;
  final Instance instance;
  final String artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(lidarrTracksProvider((instance, album.id)));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(album.title,
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            Text(artistName,
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined,
                color: AppColors.textOnPrimary),
            tooltip: 'Releases',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LidarrAlbumReleasesScreen(
                  album: album,
                  instance: instance,
                  artistName: artistName,
                ),
              ),
            ),
          ),
        ],
      ),
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(child: Text('No tracks found'));
          }
          final sorted = [...tracks]
            ..sort((a, b) {
              final ta = int.tryParse(a.trackNumber ?? '') ?? 0;
              final tb = int.tryParse(b.trackNumber ?? '') ?? 0;
              return ta.compareTo(tb);
            });
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final track = sorted[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: track.hasFile == true
                      ? AppColors.tealPrimary.withAlpha(40)
                      : AppColors.tealDark,
                  child: Text(
                    track.trackNumber ?? (index + 1).toString(),
                    style: TextStyle(
                      color: track.hasFile == true
                          ? AppColors.tealPrimary
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(track.title),
                subtitle: Text(_formatDuration(track.duration ?? 0),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                trailing: track.hasFile == true
                    ? const Icon(Icons.check_circle_outline,
                        color: AppColors.statusOnline, size: 20)
                    : const Icon(Icons.radio_button_unchecked,
                        color: AppColors.textSecondary, size: 20),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds <= 0) return '0:00';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
