import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/tautulli_home_stats.dart';
import '../api/tautulli_api.dart';
import '../providers/tautulli_providers.dart';

class TautulliStatisticsScreen extends ConsumerWidget {
  const TautulliStatisticsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(tautulliHomeStatsProvider(instance));
    final api = ref.read(tautulliApiProvider(instance));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            const Text('Failed to load statistics'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(tautulliHomeStatsProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(child: Text('No statistics available'));
        }
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async =>
              ref.invalidate(tautulliHomeStatsProvider(instance)),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (stats.topMovies.isNotEmpty)
                _StatSection(
                  title: 'Top Movies',
                  icon: Icons.movie_outlined,
                  rows: stats.topMovies,
                  api: api,
                ),
              if (stats.topTv.isNotEmpty)
                _StatSection(
                  title: 'Top TV Shows',
                  icon: Icons.tv_outlined,
                  rows: stats.topTv,
                  api: api,
                ),
              if (stats.topMusic.isNotEmpty)
                _StatSection(
                  title: 'Top Music',
                  icon: Icons.music_note_outlined,
                  rows: stats.topMusic,
                  api: api,
                ),
              if (stats.topUsers.isNotEmpty)
                _StatSection(
                  title: 'Top Users',
                  icon: Icons.people_outline,
                  rows: stats.topUsers,
                  api: api,
                  isUsers: true,
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _StatSection extends StatelessWidget {
  const _StatSection({
    required this.title,
    required this.icon,
    required this.rows,
    required this.api,
    this.isUsers = false,
  });

  final String title;
  final IconData icon;
  final List<TautulliStatRow> rows;
  final TautulliApi api;
  final bool isUsers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.tealPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.tealPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: rows.length,
            itemBuilder: (ctx, i) => _StatCard(
              row: rows[i],
              api: api,
              isUser: isUsers,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.row, required this.api, required this.isUser});

  final TautulliStatRow row;
  final TautulliApi api;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl =
        row.thumb != null && row.thumb!.isNotEmpty ? api.thumbUrl(row.thumb!) : null;

    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 80,
              height: 80,
              child: thumbUrl != null
                  ? Image.network(
                      thumbUrl,
                      fit: isUser ? BoxFit.cover : BoxFit.cover,
                      errorBuilder: (c, e, s) => _StatCardPlaceholder(isUser: isUser),
                    )
                  : _StatCardPlaceholder(isUser: isUser),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            row.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            '${row.count} plays',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatCardPlaceholder extends StatelessWidget {
  const _StatCardPlaceholder({required this.isUser});
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Icon(
        isUser ? Icons.person_outline : Icons.play_circle_outline,
        color: Colors.white24,
        size: 32,
      ),
    );
  }
}
