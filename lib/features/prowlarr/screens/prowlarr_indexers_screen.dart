import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/indexer.dart';
import '../providers/prowlarr_providers.dart';

class ProwlarrIndexersScreen extends ConsumerWidget {
  const ProwlarrIndexersScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexersAsync = ref.watch(prowlarrIndexersProvider(instance));
    final healthAsync = ref.watch(prowlarrHealthProvider(instance));

    return indexersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            Text('$e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(prowlarrIndexersProvider(instance));
                ref.invalidate(prowlarrHealthProvider(instance));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (indexers) {
        final healthIssues = healthAsync.valueOrNull
                ?.where((h) => h.type != 'ok')
                .toList() ??
            [];

        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async {
            ref.invalidate(prowlarrIndexersProvider(instance));
            ref.invalidate(prowlarrHealthProvider(instance));
          },
          child: CustomScrollView(
            slivers: [
              if (healthIssues.isNotEmpty)
                SliverToBoxAdapter(
                  child: _HealthBanner(issues: healthIssues),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${indexers.length} Indexers',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppColors.tealPrimary),
                      ),
                      const Spacer(),
                      Text(
                        '${indexers.where((i) => i.enable).length} enabled',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (indexers.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No indexers configured')),
                )
              else
                SliverList.separated(
                  itemCount: indexers.length,
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _IndexerTile(
                    indexer: indexers[i],
                    onTest: () async {
                      final api = ref.read(prowlarrApiProvider(instance));
                      final messenger = ScaffoldMessenger.of(ctx);
                      try {
                        await api.testIndexer(indexers[i].id);
                        messenger.showSnackBar(const SnackBar(
                          content: Text('Test passed'),
                          backgroundColor: AppColors.statusOnline,
                        ));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(
                          content: Text('Test failed: $e'),
                          backgroundColor: AppColors.statusOffline,
                        ));
                      }
                    },
                    onDelete: () async {
                      final messenger = ScaffoldMessenger.of(ctx);
                      final confirmed = await showDialog<bool>(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Indexer'),
                          content: Text(
                              'Delete "${indexers[i].name}"? This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.statusOffline),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      final api = ref.read(prowlarrApiProvider(instance));
                      try {
                        await api.deleteIndexer(indexers[i].id);
                        ref.invalidate(prowlarrIndexersProvider(instance));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(
                          content: Text('Delete failed: $e'),
                          backgroundColor: AppColors.statusOffline,
                        ));
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _IndexerTile extends StatelessWidget {
  const _IndexerTile({
    required this.indexer,
    required this.onTest,
    required this.onDelete,
  });

  final ProwlarrIndexer indexer;
  final VoidCallback onTest;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTorrent = indexer.protocol == 'torrent';

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (indexer.enable
                  ? AppColors.tealPrimary
                  : AppColors.statusUnknown)
              .withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          isTorrent ? Icons.cloud_download_outlined : Icons.article_outlined,
          size: 20,
          color: indexer.enable ? AppColors.tealPrimary : AppColors.statusUnknown,
        ),
      ),
      title: Text(
        indexer.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: indexer.enable ? null : AppColors.textSecondary,
        ),
      ),
      subtitle: Row(
        children: [
          _Chip(
            label: isTorrent ? 'Torrent' : 'Usenet',
            color: isTorrent ? AppColors.blueAccent : AppColors.orangeAccent,
          ),
          const SizedBox(width: 6),
          _Chip(
            label: indexer.privacy,
            color: indexer.privacy == 'public'
                ? AppColors.statusOnline
                : AppColors.statusWarning,
          ),
          if (!indexer.enable) ...[
            const SizedBox(width: 6),
            _Chip(label: 'Disabled', color: AppColors.statusUnknown),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'test') onTest();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'test',
            child: ListTile(
              leading: Icon(Icons.wifi_outlined),
              title: Text('Test'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline,
                  color: AppColors.statusOffline),
              title: Text('Delete',
                  style: TextStyle(color: AppColors.statusOffline)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _HealthBanner extends StatelessWidget {
  const _HealthBanner({required this.issues});
  final List<ProwlarrHealthItem> issues;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withAlpha(20),
        border: Border.all(color: AppColors.statusWarning.withAlpha(80)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 16, color: AppColors.statusWarning),
              const SizedBox(width: 6),
              Text(
                '${issues.length} health issue${issues.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.statusWarning,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          for (final issue in issues) ...[
            const SizedBox(height: 4),
            Text(
              '• ${issue.message}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.statusWarning),
            ),
          ],
        ],
      ),
    );
  }
}
