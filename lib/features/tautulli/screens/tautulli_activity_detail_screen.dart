import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/tautulli_activity.dart';
import '../providers/tautulli_providers.dart';

class TautulliActivityDetailScreen extends ConsumerStatefulWidget {
  const TautulliActivityDetailScreen({
    super.key,
    required this.session,
    required this.thumbUrl,
    required this.instance,
  });

  final TautulliSession session;

  /// Pre-built pms_image_proxy URL (empty string if no thumb).
  final String thumbUrl;

  final Instance instance;

  @override
  ConsumerState<TautulliActivityDetailScreen> createState() =>
      _TautulliActivityDetailScreenState();
}

class _TautulliActivityDetailScreenState
    extends ConsumerState<TautulliActivityDetailScreen> {
  bool _stopping = false;

  Future<void> _stopStream() async {
    final sessionKey = widget.session.sessionKey;
    if (sessionKey == null || sessionKey.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Stream'),
        content: Text(
          'Stop the stream for ${widget.session.friendlyName ?? widget.session.user ?? 'this user'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusOffline),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _stopping = true);
    try {
      final api = ref.read(tautulliApiProvider(widget.instance));
      await api.terminateSession(sessionKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream stopped'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _stopping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop stream: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Text(
          session.grandparentTitle?.isNotEmpty == true
              ? session.grandparentTitle!
              : session.displayTitle,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_stopping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnPrimary,
                ),
              ),
            )
          else if (session.sessionKey != null)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined,
                  color: AppColors.statusOffline),
              tooltip: 'Stop Stream',
              onPressed: _stopStream,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header: poster + title/user row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 90,
                  height: 135,
                  child: widget.thumbUrl.isNotEmpty
                      ? Image.network(
                          widget.thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, s) =>
                              _PlaceholderPoster(mediaType: session.mediaType),
                        )
                      : _PlaceholderPoster(mediaType: session.mediaType),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.grandparentTitle != null &&
                        session.grandparentTitle!.isNotEmpty) ...[
                      Text(
                        session.grandparentTitle!,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (session.parentTitle != null &&
                          session.parentTitle!.isNotEmpty)
                        Text(
                          session.parentTitle!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      Text(
                        session.displayTitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ] else
                      Text(
                        session.displayTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 8),
                    _TranscodeDecisionBadge(
                        decision: session.transcodeDecision),
                    const SizedBox(height: 6),
                    _StateBadge(state: session.state),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress
          if (session.duration > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(session.viewOffsetFormatted,
                    style: theme.textTheme.bodySmall),
                Text(session.durationFormatted,
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: session.progressFraction,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: AppColors.tealPrimary.withAlpha(20),
              color: AppColors.tealPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              '${session.progressPercent}% watched',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(),
          const SizedBox(height: 8),
          // Detail rows
          _DetailSection(title: 'Playback', rows: [
            _DetailRow(
                label: 'User',
                value: session.friendlyName ?? session.user ?? '—'),
            _DetailRow(
                label: 'Player',
                value: session.player ?? session.product ?? '—'),
            _DetailRow(label: 'IP Address', value: session.ipAddress ?? '—'),
            _DetailRow(
                label: 'Location',
                value: session.location?.toUpperCase() ?? '—'),
          ]),
          const SizedBox(height: 16),
          _DetailSection(title: 'Stream', rows: [
            _DetailRow(
                label: 'Video',
                value: [
                  if (session.videoResolution?.isNotEmpty == true)
                    session.videoResolution!,
                  if (session.videoCodec?.isNotEmpty == true)
                    session.videoCodec!.toUpperCase(),
                ].join(' / ').ifEmpty('—')),
            _DetailRow(
                label: 'Audio',
                value: session.audioCodec?.toUpperCase() ?? '—'),
            _DetailRow(
                label: 'Container',
                value: session.container?.toUpperCase() ?? '—'),
            _DetailRow(
                label: 'Bitrate',
                value: session.streamBitrate > 0
                    ? '${session.streamBitrate} kbps'
                    : '—'),
            _DetailRow(
                label: 'Quality', value: session.qualityProfile ?? '—'),
          ]),
          const SizedBox(height: 24),
          // Stop stream button
          if (session.sessionKey != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusOffline,
                side: const BorderSide(color: AppColors.statusOffline),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _stopping ? null : _stopStream,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop Stream'),
            ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _PlaceholderPoster extends StatelessWidget {
  const _PlaceholderPoster({required this.mediaType});
  final String? mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Icon(
        mediaType == 'movie'
            ? Icons.movie_outlined
            : mediaType == 'episode'
                ? Icons.tv_outlined
                : Icons.music_note_outlined,
        color: Colors.white24,
        size: 32,
      ),
    );
  }
}

class _TranscodeDecisionBadge extends StatelessWidget {
  const _TranscodeDecisionBadge({required this.decision});
  final String? decision;

  @override
  Widget build(BuildContext context) {
    final d = decision?.toLowerCase() ?? '';
    final (label, color) = d.contains('direct')
        ? ('Direct Play', AppColors.statusOnline)
        : d == 'copy'
            ? ('Direct Stream', AppColors.statusWarning)
            : d == 'transcode'
                ? ('Transcode', AppColors.statusOffline)
                : ('Unknown', AppColors.statusUnknown);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});
  final String? state;

  @override
  Widget build(BuildContext context) {
    final s = state?.toLowerCase() ?? '';
    final (label, color) = s == 'playing'
        ? ('Playing', AppColors.statusOnline)
        : s == 'paused'
            ? ('Paused', AppColors.statusWarning)
            : s == 'buffering'
                ? ('Buffering', AppColors.blueAccent)
                : ('Unknown', AppColors.statusUnknown);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
