import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';

class RadarrEditMovieScreen extends ConsumerStatefulWidget {
  const RadarrEditMovieScreen({
    super.key,
    required this.movie,
    required this.instance,
  });

  final RadarrMovie movie;
  final Instance instance;

  @override
  ConsumerState<RadarrEditMovieScreen> createState() =>
      _RadarrEditMovieScreenState();
}

class _RadarrEditMovieScreenState
    extends ConsumerState<RadarrEditMovieScreen> {
  late bool _monitored;
  int? _selectedQualityProfileId;
  String? _selectedMinAvailability;
  String? _path;
  List<int> _selectedTags = [];
  bool _saving = false;
  bool _loaded = false;

  // We hold the full raw JSON so we can PUT it back without losing fields.
  Map<String, dynamic>? _rawMovieJson;

  static const _availabilityOptions = {
    'announced': 'Announced',
    'inCinemas': 'In Cinemas',
    'released': 'Released',
  };

  @override
  void initState() {
    super.initState();
    _monitored = widget.movie.monitored;
    _selectedQualityProfileId = widget.movie.qualityProfileId;
    _selectedMinAvailability = widget.movie.minimumAvailability ?? 'released';
    _path = widget.movie.path;
    _selectedTags = List<int>.from(widget.movie.tags ?? []);
    _loadFullMovie();
  }

  Future<void> _loadFullMovie() async {
    try {
      final api = ref.read(radarrApiProvider(widget.instance));
      _rawMovieJson = await api.getMovieRaw(widget.movie.id);
      if (mounted) {
        setState(() {
          _loaded = true;
          // Sync from raw JSON in case the model was missing data
          _selectedQualityProfileId =
              _rawMovieJson!['qualityProfileId'] as int?;
          _selectedMinAvailability =
              _rawMovieJson!['minimumAvailability'] as String? ?? 'released';
          _path = _rawMovieJson!['path'] as String?;
          final rawTags = _rawMovieJson!['tags'] as List<dynamic>?;
          _selectedTags =
              rawTags?.map((e) => e as int).toList() ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load movie details: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_rawMovieJson == null) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(radarrApiProvider(widget.instance));
      _rawMovieJson!['monitored'] = _monitored;
      _rawMovieJson!['qualityProfileId'] = _selectedQualityProfileId;
      _rawMovieJson!['minimumAvailability'] = _selectedMinAvailability;
      _rawMovieJson!['path'] = _path;
      _rawMovieJson!['tags'] = _selectedTags;

      final updated = await api.updateMovie(_rawMovieJson!);
      ref.invalidate(radarrMoviesProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movie updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
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
    final profilesAsync =
        ref.watch(radarrQualityProfilesProvider(widget.instance));
    final tagsAsync = ref.watch(radarrTagsProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Movie',
                style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            Text(widget.movie.title,
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.textOnPrimary)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.textOnPrimary),
              tooltip: 'Save',
              onPressed: _loaded ? _save : null,
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Spacing.pageHorizontal),
              children: [
                // Monitored
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monitored'),
                  subtitle: const Text(
                      'Radarr will search for and download this movie'),
                  value: _monitored,
                  activeThumbColor: AppColors.tealPrimary,
                  onChanged: (v) => setState(() => _monitored = v),
                ),
                const SizedBox(height: Spacing.s16),

                // Quality Profile
                profilesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading profiles: $e'),
                  data: (profiles) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Quality Profile',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: profiles.any((p) => p.id == _selectedQualityProfileId)
                          ? _selectedQualityProfileId
                          : null,
                      items: profiles
                          .map((p) =>
                              DropdownMenuItem(value: p.id, child: Text(p.name)))
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
                  initialValue: _selectedMinAvailability,
                  items: _availabilityOptions.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedMinAvailability = v);
                    }
                  },
                ),
                const SizedBox(height: Spacing.s16),

                // Path
                TextFormField(
                  initialValue: _path,
                  decoration: const InputDecoration(
                    labelText: 'Path',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _path = v,
                ),
                const SizedBox(height: Spacing.s16),

                // Tags
                tagsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading tags: $e'),
                  data: (tags) {
                    if (tags.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tags',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: Spacing.s8),
                        Wrap(
                          spacing: Spacing.s8,
                          runSpacing: Spacing.s4,
                          children: tags.map((tag) {
                            final selected = _selectedTags.contains(tag.id);
                            return FilterChip(
                              label: Text(tag.label),
                              selected: selected,
                              selectedColor:
                                  AppColors.tealPrimary.withAlpha(40),
                              checkmarkColor: AppColors.tealPrimary,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedTags.add(tag.id);
                                  } else {
                                    _selectedTags.remove(tag.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Spacing.s48),
              ],
            ),
    );
  }
}
