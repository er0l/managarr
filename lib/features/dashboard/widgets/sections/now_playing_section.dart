import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../tautulli/api/models/tautulli_activity.dart';
import '../../../tautulli/providers/tautulli_providers.dart';

/// "Now Playing" — active Plex streams from every enabled Tautulli instance.
/// Collapses entirely when no Tautulli instance is configured or nothing
/// is streaming.
class NowPlayingSection extends ConsumerWidget {
  const NowPlayingSection({super.key, required this.instances});

  /// Enabled Tautulli instances.
  final List<Instance> instances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (instances.isEmpty) return const SizedBox.shrink();

    var anyLoading = false;
    var anyError = false;
    final cards = <Widget>[];

    for (final instance in instances) {
      final activityAsync = ref.watch(tautulliActivityProvider(instance));
      final activity = activityAsync.valueOrNull;
      if (activity != null) {
        for (final session in activity.sessions) {
          cards.add(_SessionCard(instance: instance, session: session));
        }
      } else if (activityAsync.isLoading) {
        anyLoading = true;
      } else {
        anyError = true;
      }
    }

    if (cards.isEmpty && !anyLoading && !anyError) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Now Playing',
          trailing: cards.isNotEmpty ? _CountBadge(count: cards.length) : null,
        ),
        if (cards.isNotEmpty)
          SizedBox(
            height: 132,
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
          const _LoadingRow()
        else
          const _UnreachableRow(),
      ],
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.instance, required this.session});

  final Instance instance;
  final TautulliSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final api = ref.watch(tautulliApiProvider(instance));

    // Poster goes straight through Image.network; if the instance sits
    // behind a Basic-auth reverse proxy the header must ride along.
    final useLocal = ref.watch(useLocalUrlProvider(instance.id));
    final localUrl = instance.localUrl;
    final effectiveUrl = (useLocal && localUrl != null && localUrl.isNotEmpty)
        ? localUrl
        : instance.baseUrl;
    final auth = proxyAuthFor(instance, effectiveUrl);

    final title = session.grandparentTitle?.isNotEmpty == true
        ? session.grandparentTitle!
        : session.displayTitle;
    final subtitle = session.grandparentTitle?.isNotEmpty == true
        ? session.displayTitle
        : (session.year != null ? '${session.year}' : '');
    final isPaused = session.state == 'paused';

    return SizedBox(
      width: 280,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/tautulli/${instance.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 84,
                child: session.thumb?.isNotEmpty == true
                    ? Image.network(
                        api.thumbUrl(session.thumb!),
                        fit: BoxFit.cover,
                        headers: {'Authorization': ?auth},
                        errorBuilder: (_, _, _) => const _PosterFallback(),
                      )
                    : const _PosterFallback(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            isPaused
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            size: 14,
                            color: isPaused
                                ? theme.colorScheme.onSurfaceVariant
                                : AppColors.statusOnline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${session.friendlyName ?? session.user ?? ''}'
                              ' · ${session.player ?? ''}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.s8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: session.progressFraction,
                          minHeight: 3,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: AppColors.orangeAccent,
                        ),
                      ),
                    ],
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

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.movie_outlined,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusOnline.withAlpha(25),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.statusOnline.withAlpha(80)),
      ),
      child: Text(
        '$count stream${count == 1 ? '' : 's'}',
        style: const TextStyle(
          color: AppColors.statusOnline,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
      child: Row(
        children: [
          ShimmerBox(width: 280, height: 132, borderRadius: 16),
          SizedBox(width: Spacing.s12),
          Expanded(child: ShimmerBox(height: 132, borderRadius: 16)),
        ],
      ),
    );
  }
}

class _UnreachableRow extends StatelessWidget {
  const _UnreachableRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 14, color: AppColors.statusOffline),
          const SizedBox(width: Spacing.s8),
          Text(
            'Tautulli unreachable',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
