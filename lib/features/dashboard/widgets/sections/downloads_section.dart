import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/spacing.dart';
import '../../../../core/router/module_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/service_avatar.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../providers/dashboard_providers.dart';

/// Maximum download rows shown per instance before "+N more".
const _maxRowsPerInstance = 3;

/// "Downloads" — active queue items merged across all download-capable
/// services. Each instance renders independently; an unreachable one shows
/// an inline error row without hiding the others.
class DownloadsSection extends ConsumerWidget {
  const DownloadsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(dashboardDownloadsProvider);
    if (downloads.isEmpty) return const SizedBox.shrink();

    final blocks = <Widget>[];
    var activeCount = 0;

    for (final entry in downloads) {
      final items = entry.items.valueOrNull;
      if (items != null) {
        if (items.isEmpty) continue; // idle instance — hide
        activeCount += items.length;
        blocks.add(_InstanceBlock(entry: entry));
      } else if (entry.items.isLoading) {
        blocks.add(const _LoadingBlock());
      } else {
        blocks.add(_ErrorBlock(entry: entry));
      }
    }

    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Downloads',
          trailing: activeCount > 0
              ? Text(
                  '$activeCount active',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              : null,
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
          child: Column(
            children: [
              for (var i = 0; i < blocks.length; i++) ...[
                if (i > 0) const SizedBox(height: Spacing.cardGap),
                blocks[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InstanceBlock extends StatelessWidget {
  const _InstanceBlock({required this.entry});

  final InstanceDownloads entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = entry.items.valueOrNull ?? const [];
    final visible = items.take(_maxRowsPerInstance).toList();
    final hidden = items.length - visible.length;
    final route = moduleRouteFor(entry.type, entry.instance.id);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceAvatar(type: entry.type, size: 24),
                  const SizedBox(width: Spacing.s8),
                  Expanded(
                    child: Text(
                      entry.instance.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.speedLabel != null)
                    Text(
                      '↓ ${entry.speedLabel}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.statusOnline,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.s8),
              for (final item in visible) _DownloadRow(item: item),
              if (hidden > 0)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.s4),
                  child: Text(
                    '+$hidden more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.orangeAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.item});

  final DashboardDownload item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.detail != null) ...[
                const SizedBox(width: Spacing.s8),
                Text(
                  item.detail!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: AppColors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) =>
      const ShimmerBox(height: 72, borderRadius: 16);
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.entry});

  final InstanceDownloads entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s12),
        child: Row(
          children: [
            ServiceAvatar(type: entry.type, size: 24),
            const SizedBox(width: Spacing.s8),
            Expanded(
              child: Text(
                '${entry.instance.name} unreachable',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Icon(Icons.cloud_off,
                size: 14, color: AppColors.statusOffline),
          ],
        ),
      ),
    );
  }
}
