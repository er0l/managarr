import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        title: const Text('Terminate Session'),
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
            child: const Text('Terminate'),
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
            content: Text('Stream terminated'),
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
            content: Text('Failed to terminate session: $e'),
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
    final isDark = theme.brightness == Brightness.dark;

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ──────────────────────────────────────────────────
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
                    if (session.grandparentTitle?.isNotEmpty == true) ...[
                      Text(
                        session.grandparentTitle!,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (session.parentTitle?.isNotEmpty == true)
                        Text(
                          session.parentTitle!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      Text(session.displayTitle,
                          style: theme.textTheme.bodyMedium),
                    ] else
                      Text(
                        session.displayTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 8),
                    _TranscodeDecisionBadge(decision: session.transcodeDecision),
                    const SizedBox(height: 6),
                    _StateBadge(state: session.state),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Progress bar ─────────────────────────────────────────────
          if (session.duration > 0) ...[
            LinearProgressIndicator(
              value: session.progressFraction,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: AppColors.tealPrimary.withAlpha(20),
              color: AppColors.tealPrimary,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          // ── Metadata card ────────────────────────────────────────────
          _InfoCard(
            title: 'Metadata',
            isDark: isDark,
            rows: [
              _InfoRow(
                label: 'TITLE',
                value: session.grandparentTitle?.isNotEmpty == true
                    ? session.grandparentTitle!
                    : session.displayTitle,
              ),
              if (session.year != null)
                _InfoRow(label: 'YEAR', value: '${session.year}'),
              if (session.duration > 0)
                _InfoRow(label: 'DURATION', value: session.progressFormatted),
              if (session.eta != null)
                _InfoRow(
                  label: 'ETA',
                  value: DateFormat('h:mm a').format(session.eta!),
                ),
              if (session.libraryName?.isNotEmpty == true)
                _InfoRow(label: 'LIBRARY', value: session.libraryName!),
              _InfoRow(
                label: 'USER',
                value: session.friendlyName ?? session.user ?? '—',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Player card ──────────────────────────────────────────────
          _InfoCard(
            title: 'Player',
            isDark: isDark,
            rows: [
              if (session.ipAddress?.isNotEmpty == true)
                _InfoRow(label: 'LOCATION', value: session.ipAddress!),
              if (session.platform?.isNotEmpty == true)
                _InfoRow(label: 'PLATFORM', value: session.platform!),
              if (session.product?.isNotEmpty == true)
                _InfoRow(label: 'PRODUCT', value: session.product!),
              if (session.player?.isNotEmpty == true)
                _InfoRow(label: 'PLAYER', value: session.player!),
              _InfoRow(
                label: 'QUALITY',
                value: session.qualityProfile != null
                    ? '${session.qualityProfile}'
                        '${session.streamBitrate > 0 ? ' (${session.bandwidthLabel})' : ''}'
                    : session.bandwidthLabel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Stream card ──────────────────────────────────────────────
          _InfoCard(
            title: 'Stream',
            isDark: isDark,
            rows: [
              _InfoRow(label: 'BANDWIDTH', value: session.bandwidthLabel),
              _InfoRow(label: 'STREAM', value: session.streamDecisionLabel),
              _InfoRow(label: 'CONTAINER', value: session.containerStreamLabel),
              _InfoRow(label: 'VIDEO', value: session.videoStreamLabel),
              _InfoRow(label: 'AUDIO', value: session.audioStreamLabel),
              _InfoRow(label: 'SUBTITLE', value: session.subtitleStreamLabel),
            ],
          ),
          const SizedBox(height: 24),
          // ── Terminate session button ──────────────────────────────────
          if (session.sessionKey != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusOffline,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _stopping ? null : _stopStream,
                icon: _stopping
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.close),
                label: const Text(
                  'Terminate Session',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card widget
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.rows,
    required this.isDark,
  });

  final String title;
  final List<_InfoRow> rows;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = isDark ? const Color(0xFF1A2233) : const Color(0xFFF2F4F7);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.tealPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...rows.map((row) => _InfoRowWidget(row: row)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
}

class _InfoRowWidget extends StatelessWidget {
  const _InfoRowWidget({required this.row});
  final _InfoRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              row.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value.isNotEmpty ? row.value : '—',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

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
