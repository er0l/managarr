import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/media_detail.dart';
import '../providers/seer_providers.dart';

class SeerMediaDetailScreen extends ConsumerWidget {
  const SeerMediaDetailScreen({
    super.key,
    required this.instance,
    required this.tmdbId,
    required this.mediaType,
    this.initialTitle,
  });

  final Instance instance;
  final int tmdbId;
  final String mediaType; // 'movie' or 'tv'
  final String? initialTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      seerMediaDetailProvider(
          (instance: instance, tmdbId: tmdbId, mediaType: mediaType)),
    );

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.tealPrimary,
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          title: Text(
            initialTitle ?? '',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.tealPrimary,
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          title: Text(
            initialTitle ?? '',
            style: const TextStyle(color: AppColors.textOnPrimary),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.statusOffline),
              const SizedBox(height: 12),
              Text('Failed to load: $e'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(seerMediaDetailProvider(
                    (instance: instance, tmdbId: tmdbId, mediaType: mediaType))),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.tealPrimary,
              iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
            ),
            body: const Center(child: Text('Content not found')),
          );
        }
        return _DetailScaffold(instance: instance, detail: detail);
      },
    );
  }
}

class _DetailScaffold extends ConsumerWidget {
  const _DetailScaffold({required this.instance, required this.detail});

  final Instance instance;
  final SeerMediaDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final backdropUrl = detail.backdropUrl;
    final posterUrl = detail.posterUrl;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
            title: Text(
              detail.title,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: backdropUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          backdropUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, s) =>
                              Container(color: AppColors.tealDark),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(200),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: AppColors.tealDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster + meta row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 150,
                          child: posterUrl != null
                              ? Image.network(
                                  posterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, e, s) => _PosterPlaceholder(
                                      mediaType: detail.mediaType),
                                )
                              : _PosterPlaceholder(mediaType: detail.mediaType),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (detail.year.isNotEmpty)
                                  _MetaChip(
                                    label: detail.year,
                                    icon: Icons.calendar_today,
                                  ),
                                _MetaChip(
                                  label: detail.mediaType == 'movie'
                                      ? 'Movie'
                                      : 'TV Show',
                                  icon: detail.mediaType == 'movie'
                                      ? Icons.movie_outlined
                                      : Icons.tv_outlined,
                                ),
                                if (detail.runtime > 0)
                                  _MetaChip(
                                    label: detail.mediaType == 'movie'
                                        ? '${detail.runtime}m'
                                        : '${detail.runtime}m/ep',
                                    icon: Icons.schedule,
                                  ),
                                if (detail.voteAverage > 0)
                                  _MetaChip(
                                    label:
                                        detail.voteAverage.toStringAsFixed(1),
                                    icon: Icons.star_outline,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (detail.status.isNotEmpty &&
                                detail.status != 'Unknown') ...[
                              _StatusBadge(
                                label: detail.status,
                                color: AppColors.tealPrimary,
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (detail.mediaStatus != null)
                              _RequestStatusBadge(
                                  status: detail.mediaStatus!),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Overview
                  if (detail.overview.isNotEmpty) ...[
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail.overview,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(200),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Request button
                  _RequestButton(instance: instance, detail: detail),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.mediaType});
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Icon(
        mediaType == 'movie' ? Icons.movie_outlined : Icons.tv_outlined,
        color: Colors.white24,
        size: 40,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
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

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});
  final int status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      1 => ('Pending', AppColors.statusWarning),
      2 => ('Approved', AppColors.statusOnline),
      3 => ('Declined', AppColors.statusOffline),
      4 => ('Partially Available', AppColors.statusOnline),
      5 => ('Available', AppColors.statusOnline),
      _ => ('Unknown', AppColors.statusUnknown),
    };
    return _StatusBadge(label: label, color: color);
  }
}

// ─── Request button ───────────────────────────────────────────────────────────

class _RequestButton extends ConsumerStatefulWidget {
  const _RequestButton({required this.instance, required this.detail});
  final Instance instance;
  final SeerMediaDetail detail;

  @override
  ConsumerState<_RequestButton> createState() => _RequestButtonState();
}

class _RequestButtonState extends ConsumerState<_RequestButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final mediaStatus = widget.detail.mediaStatus;

    if (mediaStatus == 5 || mediaStatus == 4) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
              mediaStatus == 5 ? 'Available' : 'Partially Available'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.statusOnline.withAlpha(30),
            foregroundColor: AppColors.statusOnline,
            disabledBackgroundColor: AppColors.statusOnline.withAlpha(30),
            disabledForegroundColor: AppColors.statusOnline,
          ),
        ),
      );
    }

    if (mediaStatus == 1 || mediaStatus == 2) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top_outlined),
          label: const Text('Request Pending'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.statusWarning.withAlpha(30),
            foregroundColor: AppColors.statusWarning,
            disabledBackgroundColor: AppColors.statusWarning.withAlpha(30),
            disabledForegroundColor: AppColors.statusWarning,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _loading ? null : _request,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add),
        label: const Text('Request'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orangeAccent,
        ),
      ),
    );
  }

  Future<void> _request() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(seerApiProvider(widget.instance));
      await api.requestMedia(
        tmdbId: widget.detail.id,
        mediaType: widget.detail.mediaType,
      );
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Request submitted successfully'),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Request failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _loading = false);
      }
    }
  }
}
