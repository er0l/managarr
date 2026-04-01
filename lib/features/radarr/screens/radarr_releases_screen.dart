import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/release.dart';
import '../providers/radarr_providers.dart';

class RadarrReleasesScreen extends ConsumerWidget {
  const RadarrReleasesScreen({
    super.key,
    required this.instance,
    required this.movieId,
    required this.movieTitle,
  });

  final Instance instance;
  final int movieId;
  final String movieTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releasesAsync = ref.watch(
        radarrReleasesProvider((instance: instance, movieId: movieId)));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Releases',
                style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            Text(movieTitle,
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
          ],
        ),
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
                  onPressed: () => ref.invalidate(radarrReleasesProvider(
                      (instance: instance, movieId: movieId))),
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
          return ListView.builder(
            padding:
                const EdgeInsets.only(top: Spacing.s8, bottom: Spacing.s24),
            itemCount: releases.length,
            itemBuilder: (context, index) => _ReleaseTile(
              release: releases[index],
              instance: instance,
              ref: ref,
            ),
          );
        },
      ),
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({
    required this.release,
    required this.instance,
    required this.ref,
  });

  final RadarrRelease release;
  final Instance instance;
  final WidgetRef ref;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _grab(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grab Release'),
        content: Text(
            'Download "${release.title}"?\n\nQuality: ${release.qualityName}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.orangeAccent),
            child: const Text('Grab'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(radarrApiProvider(instance));
      await api.grabRelease(release.guid, release.indexerId ?? 0);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Release grabbed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isApproved = release.approved;
    final protocol = release.protocol ?? '';
    final isTorrent = protocol.toLowerCase() == 'torrent';

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: Spacing.pageHorizontal, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _grab(context),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(release.title,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: Spacing.s8),
              // Meta row
              Wrap(
                spacing: Spacing.s8,
                runSpacing: Spacing.s4,
                children: [
                  _MiniChip(
                    label: release.qualityName,
                    color: isApproved
                        ? AppColors.statusOnline
                        : AppColors.statusWarning,
                  ),
                  if (release.size != null && release.size! > 0)
                    _MiniChip(
                        label: _formatSize(release.size!),
                        color: AppColors.tealPrimary),
                  _MiniChip(
                    label: isTorrent ? 'Torrent' : 'Usenet',
                    color: AppColors.blueAccent,
                  ),
                  if (isTorrent && release.seeders != null)
                    _MiniChip(
                        label: '${release.seeders}S / ${release.leechers ?? 0}L',
                        color: release.seeders! > 0
                            ? AppColors.statusOnline
                            : AppColors.statusOffline),
                  if (release.indexer != null)
                    _MiniChip(
                        label: release.indexer!,
                        color: AppColors.textSecondary),
                  if (release.age != null)
                    _MiniChip(
                        label: '${release.age}d',
                        color: AppColors.textSecondary),
                  if (release.customFormatScore != null &&
                      release.customFormatScore! != 0)
                    _MiniChip(
                      label: 'CF: ${release.customFormatScore}',
                      color: release.customFormatScore! > 0
                          ? AppColors.statusOnline
                          : AppColors.statusOffline,
                    ),
                ],
              ),
              if (release.rejected &&
                  release.rejections != null &&
                  release.rejections!.isNotEmpty) ...[
                const SizedBox(height: Spacing.s8),
                Text(
                  release.rejections!.join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.statusOffline, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
