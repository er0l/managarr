import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';

class RadarrAddMovieDetailScreen extends ConsumerStatefulWidget {
  const RadarrAddMovieDetailScreen({
    super.key,
    required this.movie,
    required this.instance,
  });

  final RadarrMovie movie;
  final Instance instance;

  @override
  ConsumerState<RadarrAddMovieDetailScreen> createState() =>
      _RadarrAddMovieDetailScreenState();
}

class _RadarrAddMovieDetailScreenState
    extends ConsumerState<RadarrAddMovieDetailScreen> {
  bool _monitored = true;
  bool _searchOnAdd = true;
  int? _selectedQualityProfileId;
  String? _selectedRootFolderPath;
  String _minimumAvailability = 'released';
  bool _saving = false;

  static const _availabilityOptions = {
    'announced': 'Announced',
    'inCinemas': 'In Cinemas',
    'released': 'Released',
  };

  Future<void> _addMovie() async {
    if (_selectedQualityProfileId == null || _selectedRootFolderPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a quality profile and root folder'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(radarrApiProvider(widget.instance));
      final movieJson = widget.movie.toJson();
      movieJson['qualityProfileId'] = _selectedQualityProfileId;
      movieJson['rootFolderPath'] = _selectedRootFolderPath;
      movieJson['monitored'] = _monitored;
      movieJson['minimumAvailability'] = _minimumAvailability;
      movieJson['addOptions'] = {
        'searchForMovie': _searchOnAdd,
      };
      // Remove id=0 for new additions — Radarr expects no id field
      movieJson.remove('id');

      await api.addMovie(movieJson);
      ref.invalidate(radarrMoviesProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.movie.title}" added to Radarr'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop both detail and search screens
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding movie: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movie = widget.movie;
    final profilesAsync =
        ref.watch(radarrQualityProfilesProvider(widget.instance));
    final rootFoldersAsync =
        ref.watch(radarrRootFoldersProvider(widget.instance));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: _BackdropHeader(movie: movie),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              title: Text(
                movie.title,
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.pageHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta chips
                  Wrap(
                    spacing: Spacing.s8,
                    runSpacing: Spacing.s4,
                    children: [
                      if (movie.year > 0)
                        _InfoChip(
                            label: movie.year.toString(),
                            icon: Icons.calendar_today),
                      if (movie.runtime != null && movie.runtime! > 0)
                        _InfoChip(
                            label: '${movie.runtime}m',
                            icon: Icons.timer_outlined),
                      if (movie.studio != null)
                        _InfoChip(
                            label: movie.studio!,
                            icon: Icons.business_outlined),
                    ],
                  ),
                  if (movie.overview != null &&
                      movie.overview!.isNotEmpty) ...[
                    const SizedBox(height: Spacing.s16),
                    Text(
                      movie.overview!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary, height: 1.55),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: Spacing.s24),
                  const Divider(),
                  const SizedBox(height: Spacing.s16),
                  Text('Configuration',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: Spacing.s16),

                  // Root Folder
                  rootFoldersAsync.when(
                    loading: () => const _FieldSkeleton(label: 'Root Folder'),
                    error: (e, _) => _FieldError(label: 'Root Folder'),
                    data: (folders) {
                      _selectedRootFolderPath ??=
                          folders.isNotEmpty ? folders.first.path : null;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Root Folder',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedRootFolderPath,
                        items: folders
                            .map((f) => DropdownMenuItem(
                                value: f.path, child: Text(f.path)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedRootFolderPath = v),
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.s16),

                  // Quality Profile
                  profilesAsync.when(
                    loading: () =>
                        const _FieldSkeleton(label: 'Quality Profile'),
                    error: (e, _) => _FieldError(label: 'Quality Profile'),
                    data: (profiles) {
                      _selectedQualityProfileId ??=
                          profiles.isNotEmpty ? profiles.first.id : null;
                      return DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Quality Profile',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedQualityProfileId,
                        items: profiles
                            .map((p) => DropdownMenuItem(
                                value: p.id, child: Text(p.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedQualityProfileId = v),
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.s16),

                  // Minimum Availability
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Minimum Availability',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _minimumAvailability,
                    items: _availabilityOptions.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _minimumAvailability = v);
                    },
                  ),
                  const SizedBox(height: Spacing.s16),

                  // Monitored toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Monitored'),
                    subtitle: const Text(
                        'Radarr will search for and download this movie'),
                    value: _monitored,
                    activeThumbColor: AppColors.tealPrimary,
                    onChanged: (v) => setState(() => _monitored = v),
                  ),

                  // Search on add toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Search on Add'),
                    subtitle: const Text(
                        'Immediately search for the movie when added'),
                    value: _searchOnAdd,
                    activeThumbColor: AppColors.tealPrimary,
                    onChanged: (v) => setState(() => _searchOnAdd = v),
                  ),
                  const SizedBox(height: Spacing.s24),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _addMovie,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: Spacing.s16),
                        shape: const StadiumBorder(),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add),
                      label: Text(_saving ? 'Adding…' : 'Add Movie'),
                    ),
                  ),
                  const SizedBox(height: Spacing.s48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({required this.movie});
  final RadarrMovie movie;

  @override
  Widget build(BuildContext context) {
    final fanart = movie.fanartUrl;
    final poster = movie.posterUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (fanart != null)
          Image.network(fanart, fit: BoxFit.cover,
              errorBuilder: (_, e, s) => _ColoredFallback(movie: movie))
        else
          _ColoredFallback(movie: movie),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.4, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 52,
          left: 16,
          child: Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 8)
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: poster != null
                ? Image.network(poster, fit: BoxFit.cover)
                : Container(color: AppColors.tealDark),
          ),
        ),
      ],
    );
  }
}

class _ColoredFallback extends StatelessWidget {
  const _ColoredFallback({required this.movie});
  final RadarrMovie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        movie.title.isNotEmpty ? movie.title[0] : 'R',
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 96,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tealPrimary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tealPrimary.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.tealPrimary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.tealPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: const SizedBox(
        height: 20,
        child: Center(
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: 'Failed to load',
      ),
      child: const SizedBox.shrink(),
    );
  }
}
