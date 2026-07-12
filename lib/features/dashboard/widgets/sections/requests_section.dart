import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../seer/api/models/media_request.dart';
import '../../../seer/providers/seer_providers.dart';

/// "Requests" — pending Seer/Overseerr requests as a horizontal poster rail.
/// Collapses when no Seer instance is configured or nothing is pending.
class RequestsSection extends ConsumerWidget {
  const RequestsSection({super.key, required this.instances});

  /// Enabled Seer instances.
  final List<Instance> instances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (instances.isEmpty) return const SizedBox.shrink();

    var anyLoading = false;
    final cards = <Widget>[];

    for (final instance in instances) {
      final requestsAsync = ref.watch(seerRequestsProvider(instance));
      final requests = requestsAsync.valueOrNull;
      if (requests != null) {
        for (final request in requests.where((r) => r.status == 1)) {
          cards.add(_RequestCard(instance: instance, request: request));
        }
      } else if (requestsAsync.isLoading) {
        anyLoading = true;
      }
      // Unreachable Seer: skip silently — the status strip shows it offline.
    }

    if (cards.isEmpty && !anyLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Requests',
          trailing: cards.isNotEmpty
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orangeAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: AppColors.orangeAccent.withAlpha(80)),
                  ),
                  child: Text(
                    '${cards.length} pending',
                    style: const TextStyle(
                      color: AppColors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        if (cards.isNotEmpty)
          SizedBox(
            height: 196,
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
        else
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
        onTap: () => context.push('/seer/${instance.id}'),
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
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
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
