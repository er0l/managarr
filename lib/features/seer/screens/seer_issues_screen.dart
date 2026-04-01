import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/seer_issue.dart';
import '../providers/seer_providers.dart';

class SeerIssuesScreen extends ConsumerWidget {
  const SeerIssuesScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(seerIssuesProvider(instance));
    final statusFilter = ref.watch(seerIssueStatusFilterProvider(instance.id));
    final typeFilter = ref.watch(seerIssueTypeFilterProvider(instance.id));
    final filtered = ref.watch(seerFilteredIssuesProvider(instance));

    return Column(
      children: [
        _FilterBar(instance: instance, statusFilter: statusFilter, typeFilter: typeFilter),
        Expanded(
          child: issuesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load issues', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(e.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(seerIssuesProvider(instance)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (_) {
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bug_report_outlined,
                          size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No issues found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(seerIssuesProvider(instance)),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _IssueTile(issue: filtered[index], instance: instance, ref: ref),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.instance,
    required this.statusFilter,
    required this.typeFilter,
  });

  final Instance instance;
  final SeerIssueStatusFilter statusFilter;
  final SeerIssueTypeFilter typeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          // Status filters
          for (final filter in SeerIssueStatusFilter.values)
            FilterChip(
              label: Text(switch (filter) {
                SeerIssueStatusFilter.all => 'All',
                SeerIssueStatusFilter.open => 'Open',
                SeerIssueStatusFilter.resolved => 'Resolved',
              }),
              selected: statusFilter == filter,
              onSelected: (_) => ref
                  .read(seerIssueStatusFilterProvider(instance.id).notifier)
                  .state = filter,
            ),
          const SizedBox(width: 4),
          // Type filters
          for (final filter in SeerIssueTypeFilter.values)
            if (filter != SeerIssueTypeFilter.all)
              FilterChip(
                label: Text(switch (filter) {
                  SeerIssueTypeFilter.all => '',
                  SeerIssueTypeFilter.video => 'Video',
                  SeerIssueTypeFilter.audio => 'Audio',
                  SeerIssueTypeFilter.subtitle => 'Subtitle',
                  SeerIssueTypeFilter.other => 'Other',
                }),
                selected: typeFilter == filter,
                onSelected: (_) {
                  final notifier =
                      ref.read(seerIssueTypeFilterProvider(instance.id).notifier);
                  notifier.state =
                      typeFilter == filter ? SeerIssueTypeFilter.all : filter;
                },
              ),
        ],
      ),
    );
  }
}

// ─── Issue tile ──────────────────────────────────────────────────────────────

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.issue,
    required this.instance,
    required this.ref,
  });

  final SeerIssue issue;
  final Instance instance;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = issue.isOpen;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _IssueTypeIcon(issueType: issue.issueType),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${issue.mediaLabel} Issue #${issue.id}',
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(isOpen: isOpen),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.label_outline, size: 14,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(issue.issueTypeName,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              if (issue.problemSeason != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.tv, size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'S${issue.problemSeason!.toString().padLeft(2, '0')}'
                  '${issue.problemEpisode != null ? 'E${issue.problemEpisode!.toString().padLeft(2, '0')}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (issue.commentCount > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.chat_bubble_outline, size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${issue.commentCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
          if (issue.createdByName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(issue.createdByName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                Text(
                  _formatDate(issue.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
      onTap: () => _showDetail(context),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _IssueDetailSheet(issue: issue, instance: instance, ref: ref),
    );
  }
}

// ─── Issue type icon ─────────────────────────────────────────────────────────

class _IssueTypeIcon extends StatelessWidget {
  const _IssueTypeIcon({required this.issueType});

  final int issueType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (issueType) {
      1 => (Icons.videocam_outlined, Colors.blue),
      2 => (Icons.volume_up_outlined, Colors.purple),
      3 => (Icons.subtitles_outlined, Colors.teal),
      _ => (Icons.bug_report_outlined, Colors.orange),
    };
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withAlpha(30),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        isOpen ? 'Open' : 'Resolved',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ─── Detail sheet ─────────────────────────────────────────────────────────────

class _IssueDetailSheet extends StatelessWidget {
  const _IssueDetailSheet({
    required this.issue,
    required this.instance,
    required this.ref,
  });

  final SeerIssue issue;
  final Instance instance;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  // Header
                  Row(
                    children: [
                      _IssueTypeIcon(issueType: issue.issueType),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${issue.mediaLabel} Issue #${issue.id}',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              issue.issueTypeName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(isOpen: issue.isOpen),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Details grid
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Type',
                    value: issue.issueTypeName,
                  ),
                  _DetailRow(
                    icon: Icons.movie_outlined,
                    label: 'Media',
                    value: issue.mediaLabel,
                  ),
                  if (issue.problemSeason != null)
                    _DetailRow(
                      icon: Icons.tv,
                      label: 'Episode',
                      value:
                          'Season ${issue.problemSeason}${issue.problemEpisode != null ? ', Episode ${issue.problemEpisode}' : ''}',
                    ),
                  if (issue.createdByName != null)
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: 'Reported by',
                      value: issue.createdByName!,
                    ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Created',
                    value: _formatDateTime(issue.createdAt),
                  ),
                  _DetailRow(
                    icon: Icons.update_outlined,
                    label: 'Updated',
                    value: _formatDateTime(issue.updatedAt),
                  ),
                  if (issue.commentCount > 0)
                    _DetailRow(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comments',
                      value: issue.commentCount.toString(),
                    ),

                  const SizedBox(height: 24),

                  // Action button
                  FilledButton.icon(
                    onPressed: () => _toggleStatus(context),
                    icon: Icon(issue.isOpen ? Icons.check_circle_outline : Icons.radio_button_unchecked),
                    label: Text(issue.isOpen ? 'Mark as Resolved' : 'Reopen Issue'),
                    style: FilledButton.styleFrom(
                      backgroundColor: issue.isOpen ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleStatus(BuildContext context) async {
    final api = ref.read(seerApiProvider(instance));
    final newStatus = issue.isOpen ? 2 : 1;
    try {
      await api.updateIssueStatus(issue.id, newStatus);
      ref.invalidate(seerIssuesProvider(instance));
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update issue: $e')),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
