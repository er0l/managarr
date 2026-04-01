import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/tautulli_providers.dart';
import 'tautulli_activity_detail_screen.dart';

class TautulliActivityScreen extends ConsumerWidget {
  const TautulliActivityScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(tautulliActivityProvider(instance));
    final api = ref.read(tautulliApiProvider(instance));

    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (activity) {
        if (activity.sessions.isEmpty) {
          return const Center(child: Text('No active sessions'));
        }

        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async =>
              ref.invalidate(tautulliActivityProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: activity.sessions.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final session = activity.sessions[index];
              final thumbUrl =
                  session.thumb != null && session.thumb!.isNotEmpty
                      ? api.thumbUrl(session.thumb!)
                      : '';
              final titleLine = session.grandparentTitle != null &&
                      session.grandparentTitle!.isNotEmpty
                  ? '${session.grandparentTitle} – ${session.displayTitle}'
                  : session.displayTitle;
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TautulliActivityDetailScreen(
                      session: session,
                      thumbUrl: thumbUrl,
                      instance: instance,
                    ),
                  ),
                ),
                title: Text(
                  titleLine,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${session.friendlyName ?? session.user ?? 'Unknown User'} • ${session.product ?? session.player ?? 'Unknown Player'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: session.progressFraction,
                      backgroundColor: AppColors.tealPrimary.withAlpha(20),
                      color: AppColors.tealPrimary,
                      minHeight: 4,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          session.state?.toUpperCase() ?? 'UNKNOWN',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: session.state == 'playing'
                                    ? AppColors.statusOnline
                                    : AppColors.statusWarning,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${session.progressPercent}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
              );
            },
          ),
        );
      },
    );
  }
}
