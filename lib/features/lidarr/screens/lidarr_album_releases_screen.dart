import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/album.dart';
import '../api/models/release.dart';
import '../providers/lidarr_providers.dart';

class LidarrAlbumReleasesScreen extends ConsumerWidget {
  const LidarrAlbumReleasesScreen({
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
    final releasesAsync = ref.watch(lidarrAlbumReleasesProvider(
        (instance: instance, albumId: album.id)));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: () => ref.invalidate(lidarrAlbumReleasesProvider(
                (instance: instance, albumId: album.id))),
          ),
        ],
      ),
      body: releasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off,
                    size: 48, color: AppColors.statusOffline),
                const SizedBox(height: Spacing.s16),
                Text('Failed to load releases',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Spacing.s8),
                Text(e.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 3),
                const SizedBox(height: Spacing.s24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(
                      lidarrAlbumReleasesProvider(
                          (instance: instance, albumId: album.id))),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: const StadiumBorder()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (releases) {
          if (releases.isEmpty) {
            return Center(
              child: Text('No releases found',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: Spacing.s24),
            itemCount: releases.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _ReleaseTile(
              release: releases[index],
              instance: instance,
            ),
          );
        },
      ),
    );
  }
}

class _ReleaseTile extends StatefulWidget {
  const _ReleaseTile({required this.release, required this.instance});

  final LidarrRelease release;
  final Instance instance;

  @override
  State<_ReleaseTile> createState() => _ReleaseTileState();
}

class _ReleaseTileState extends State<_ReleaseTile> {
  bool _grabbing = false;

  Future<void> _grab(BuildContext context, WidgetRef ref) async {
    final indexerId = widget.release.indexerId ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grab Release'),
        content: Text('Download "${widget.release.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealPrimary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Grab'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _grabbing = true);
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      await api.grabRelease(widget.release.guid, indexerId);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Release grabbed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _grabbing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final release = widget.release;
        final theme = Theme.of(context);
        final isApproved = release.approved;
        final sizeGb = release.size != null
            ? release.size! / (1024 * 1024 * 1024)
            : null;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.pageHorizontal, vertical: 6),
          title: Text(
            release.title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isApproved ? null : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (release.qualityName.isNotEmpty)
                  _Chip(label: release.qualityName, color: AppColors.tealPrimary),
                if (sizeGb != null)
                  _Chip(
                    label: sizeGb >= 1
                        ? '${sizeGb.toStringAsFixed(2)} GB'
                        : '${(sizeGb * 1024).toStringAsFixed(0)} MB',
                    color: AppColors.textSecondary,
                  ),
                if (release.protocol != null)
                  _Chip(
                    label: release.protocol!.toUpperCase(),
                    color: release.protocol == 'torrent'
                        ? AppColors.blueAccent
                        : AppColors.orangeAccent,
                  ),
                if (release.protocol == 'torrent' && release.seeders != null)
                  _Chip(
                    label: 'S:${release.seeders} L:${release.leechers ?? 0}',
                    color: (release.seeders ?? 0) > 0
                        ? AppColors.statusOnline
                        : AppColors.statusOffline,
                  ),
                if (release.indexer != null)
                  _Chip(label: release.indexer!, color: AppColors.textSecondary),
                if (release.age != null)
                  _Chip(
                      label: '${release.age}d',
                      color: AppColors.textSecondary),
                if (!isApproved && (release.rejections?.isNotEmpty ?? false))
                  _Chip(
                    label: release.rejections!.first,
                    color: AppColors.statusOffline,
                  ),
              ],
            ),
          ),
          trailing: _grabbing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.download_outlined),
                  color: isApproved
                      ? AppColors.tealPrimary
                      : AppColors.textSecondary,
                  onPressed: () => _grab(context, ref),
                ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
