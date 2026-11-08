import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../seer/api/models/media_request.dart';
import '../../../seer/providers/seer_providers.dart';
import '../../../seer/screens/seer_media_detail_screen.dart';

/// Latest Seer requests across all statuses and enabled instances.
class RequestsSection extends ConsumerWidget {
  const RequestsSection({super.key, required this.instances});

  /// Enabled Seer instances.
  final List<Instance> instances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (instances.isEmpty) return const SizedBox.shrink();

    var anyLoading = false;
    final recent = <({Instance instance, SeerMediaRequest request})>[];
    final failed = <Instance>[];
    for (final instance in instances) {
      final result = ref.watch(seerRequestsProvider(instance));
      if (result.hasError) failed.add(instance);
      if (result.isLoading) anyLoading = true;
      for (final request in result.valueOrNull ?? <SeerMediaRequest>[]) {
        recent.add((instance: instance, request: request));
      }
    }
    recent.sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));
    final cards = [
      for (final item in recent.take(20))
        _RequestCard(instance: item.instance, request: item.request),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Requests'),
        for (final instance in failed)
          ListTile(
            title: Text('Requests unavailable · ${instance.name}'),
            trailing: TextButton(
              onPressed: () => ref.invalidate(seerRequestsProvider(instance)),
              child: const Text('Retry'),
            ),
          ),
        if (cards.isEmpty && !anyLoading && failed.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
            child: Text('No recent requests'),
          ),
        if (cards.isNotEmpty)
          SizedBox(
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.pageHorizontal,
              ),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: Spacing.s12),
              itemBuilder: (context, index) => cards[index],
            ),
          )
        else if (anyLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
            child: Row(
              children: [
                ShimmerBox(width: 100, height: 150, borderRadius: 12),
                SizedBox(width: Spacing.s12),
                ShimmerBox(width: 100, height: 150, borderRadius: 12),
              ],
            ),
          ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.instance, required this.request});

  final Instance instance;
  final SeerMediaRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = request.posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w185${request.posterPath}'
        : null;

    return SizedBox(
      width: 100,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeerMediaDetailScreen(
              instance: instance,
              tmdbId: request.tmdbId,
              mediaType: request.mediaType,
              initialTitle: request.title,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 150,
                child: posterUrl != null
                    ? Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _PosterFallback(),
                      )
                    : const _PosterFallback(),
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              request.title,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              request.statusText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: request.statusColor,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              request.requestedBy,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.pending_outlined,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }
}
