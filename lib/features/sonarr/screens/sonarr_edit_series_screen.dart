import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/series.dart';
import '../providers/sonarr_providers.dart';

class SonarrEditSeriesScreen extends ConsumerStatefulWidget {
  const SonarrEditSeriesScreen({
    super.key,
    required this.series,
    required this.instance,
  });

  final SonarrSeries series;
  final Instance instance;

  @override
  ConsumerState<SonarrEditSeriesScreen> createState() =>
      _SonarrEditSeriesScreenState();
}

class _SonarrEditSeriesScreenState
    extends ConsumerState<SonarrEditSeriesScreen> {
  late bool _monitored;
  int? _selectedQualityProfileId;
  String? _selectedSeriesType;
  String? _path;
  List<int> _selectedTags = [];
  bool _saving = false;
  bool _loaded = false;

  Map<String, dynamic>? _rawSeriesJson;

  static const _seriesTypeOptions = {
    'standard': 'Standard',
    'daily': 'Daily',
    'anime': 'Anime',
  };

  @override
  void initState() {
    super.initState();
    _monitored = widget.series.monitored;
    _selectedQualityProfileId = widget.series.qualityProfileId;
    _selectedSeriesType = widget.series.seriesType ?? 'standard';
    _path = widget.series.path;
    _selectedTags = List<int>.from(widget.series.tags ?? []);
    _loadFullSeries();
  }

  Future<void> _loadFullSeries() async {
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      _rawSeriesJson = await api.getSeriesRaw(widget.series.id);
      if (mounted) {
        setState(() {
          _loaded = true;
          _selectedQualityProfileId =
              _rawSeriesJson!['qualityProfileId'] as int?;
          _selectedSeriesType =
              _rawSeriesJson!['seriesType'] as String? ?? 'standard';
          _path = _rawSeriesJson!['path'] as String?;
          final rawTags = _rawSeriesJson!['tags'] as List<dynamic>?;
          _selectedTags = rawTags?.map((e) => e as int).toList() ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load series details: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_rawSeriesJson == null) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      _rawSeriesJson!['monitored'] = _monitored;
      _rawSeriesJson!['qualityProfileId'] = _selectedQualityProfileId;
      _rawSeriesJson!['seriesType'] = _selectedSeriesType;
      _rawSeriesJson!['path'] = _path;
      _rawSeriesJson!['tags'] = _selectedTags;

      final updated = await api.updateSeries(_rawSeriesJson!);
      ref.invalidate(sonarrSeriesProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Series updated'),
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
        ref.watch(sonarrQualityProfilesProvider(widget.instance));
    final tagsAsync = ref.watch(sonarrTagsProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Series',
                style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            Text(widget.series.title,
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
                      'Sonarr will search for new episodes of this series'),
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
                      initialValue: profiles
                              .any((p) => p.id == _selectedQualityProfileId)
                          ? _selectedQualityProfileId
                          : null,
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

                // Series Type
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Series Type',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _seriesTypeOptions.containsKey(_selectedSeriesType)
                      ? _selectedSeriesType
                      : 'standard',
                  items: _seriesTypeOptions.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSeriesType = v);
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
                    if (tags.isEmpty) return const SizedBox.shrink();
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
