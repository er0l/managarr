import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/seer_user.dart';
import '../api/models/media_request.dart';
import '../providers/seer_providers.dart';

class SeerUsersScreen extends ConsumerWidget {
  const SeerUsersScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(seerUsersProvider(instance));

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load users',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(e.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(seerUsersProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No users found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(seerUsersProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _UserTile(
              user: users[index],
              instance: instance,
            ),
          ),
        );
      },
    );
  }
}

// ─── User tile ────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.instance});

  final SeerUser user;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _UserAvatar(user: user),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.displayName,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                user.isPlexUser ? Icons.play_circle_outline : Icons.person_outline,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                user.isPlexUser ? 'Plex' : 'Local',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Icon(Icons.movie_filter_outlined,
                  size: 13, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${user.requestCount} request${user.requestCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          // Quota bars if applicable
          if (user.hasMovieQuota || user.hasTvQuota) ...[
            const SizedBox(height: 6),
            if (user.hasMovieQuota)
              _QuotaRow(
                icon: Icons.movie_outlined,
                label: 'Movies',
                used: user.movieQuotaUsed,
                limit: user.movieQuotaLimit,
                percent: user.movieQuotaPercent,
              ),
            if (user.hasTvQuota) ...[
              if (user.hasMovieQuota) const SizedBox(height: 4),
              _QuotaRow(
                icon: Icons.tv,
                label: 'TV',
                used: user.tvQuotaUsed,
                limit: user.tvQuotaLimit,
                percent: user.tvQuotaPercent,
              ),
            ],
          ],
        ],
      ),
      onTap: () => _openDetail(context),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _UserDetailScreen(user: user, instance: instance),
      ),
    );
  }
}

// ─── User avatar ──────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final SeerUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(user.avatar!),
        onBackgroundImageError: (_, _) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }
}

// ─── Quota row ────────────────────────────────────────────────────────────────

class _QuotaRow extends StatelessWidget {
  const _QuotaRow({
    required this.icon,
    required this.label,
    required this.used,
    required this.limit,
    required this.percent,
  });

  final IconData icon;
  final String label;
  final int used;
  final int limit;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color barColor = percent >= 0.9
        ? Colors.red
        : percent >= 0.7
            ? Colors.orange
            : theme.colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor:
                  theme.colorScheme.onSurfaceVariant.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$used/$limit',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }
}

// ─── User detail screen ───────────────────────────────────────────────────────

class _UserDetailScreen extends ConsumerWidget {
  const _UserDetailScreen({required this.user, required this.instance});

  final SeerUser user;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(
        seerUserRequestsProvider((instance: instance, userId: user.id)));

    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                _UserAvatar(user: user),
                const SizedBox(height: 12),
                Text(user.displayName, style: theme.textTheme.headlineSmall),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.isAdmin)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Admin',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer)),
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.isPlexUser ? 'Plex User' : 'Local User',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats row
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    value: user.requestCount.toString(),
                    label: 'Requests',
                    icon: Icons.movie_filter_outlined,
                  ),
                  if (user.hasMovieQuota)
                    _StatBox(
                      value: '${user.movieQuotaUsed}/${user.movieQuotaLimit}',
                      label: 'Movie Quota',
                      icon: Icons.movie_outlined,
                      color: _quotaColor(user.movieQuotaPercent),
                    ),
                  if (user.hasTvQuota)
                    _StatBox(
                      value: '${user.tvQuotaUsed}/${user.tvQuotaLimit}',
                      label: 'TV Quota',
                      icon: Icons.tv,
                      color: _quotaColor(user.tvQuotaPercent),
                    ),
                  _StatBox(
                    value: _formatDate(user.createdAt),
                    label: 'Joined',
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Requests section
          Text('Recent Requests',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          requestsAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load requests: $e',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No requests yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                );
              }
              return Column(
                children: requests
                    .take(20)
                    .map((r) => _RequestRow(request: r))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _quotaColor(double percent) {
    if (percent >= 0.9) return Colors.red;
    if (percent >= 0.7) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ─── Stat box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Column(
      children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: c)),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Request row ──────────────────────────────────────────────────────────────

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final SeerMediaRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusColor, statusLabel) = switch (request.status) {
      1 => (Colors.orange, 'Pending'),
      2 => (Colors.blue, 'Approved'),
      3 => (Colors.red, 'Declined'),
      4 => (Colors.teal, 'Partial'),
      5 => (Colors.green, 'Available'),
      _ => (Colors.grey, 'Unknown'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${request.mediaType == 'movie' ? 'Movie' : 'TV'} · $statusLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(request.createdAt),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
