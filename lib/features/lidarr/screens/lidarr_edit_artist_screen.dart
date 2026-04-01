import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/artist.dart';
import '../providers/lidarr_providers.dart';

class LidarrEditArtistScreen extends ConsumerStatefulWidget {
  const LidarrEditArtistScreen({
    super.key,
    required this.artist,
    required this.instance,
  });

  final LidarrArtist artist;
  final Instance instance;

  @override
  ConsumerState<LidarrEditArtistScreen> createState() =>
      _LidarrEditArtistScreenState();
}

class _LidarrEditArtistScreenState
    extends ConsumerState<LidarrEditArtistScreen> {
  late bool _monitored;
  int? _selectedQualityProfileId;
  int? _selectedMetadataProfileId;
  String? _path;
  List<int> _selectedTags = [];
  bool _saving = false;
  bool _loaded = false;

  Map<String, dynamic>? _rawArtistJson;

  @override
  void initState() {
    super.initState();
    _monitored = widget.artist.monitored;
    _selectedQualityProfileId = widget.artist.qualityProfileId;
    _selectedMetadataProfileId = widget.artist.metadataProfileId;
    _path = widget.artist.path;
    _selectedTags = List<int>.from(widget.artist.tags ?? []);
    _loadFullArtist();
  }

  Future<void> _loadFullArtist() async {
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      _rawArtistJson = await api.getArtistRaw(widget.artist.id);
      if (mounted) {
        setState(() {
          _loaded = true;
          _selectedQualityProfileId =
              _rawArtistJson!['qualityProfileId'] as int?;
          _selectedMetadataProfileId =
              _rawArtistJson!['metadataProfileId'] as int?;
          _path = _rawArtistJson!['path'] as String?;
          final rawTags = _rawArtistJson!['tags'] as List<dynamic>?;
          _selectedTags = rawTags?.map((e) => e as int).toList() ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load artist details: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_rawArtistJson == null) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      _rawArtistJson!['monitored'] = _monitored;
      _rawArtistJson!['qualityProfileId'] = _selectedQualityProfileId;
      _rawArtistJson!['metadataProfileId'] = _selectedMetadataProfileId;
      _rawArtistJson!['path'] = _path;
      _rawArtistJson!['tags'] = _selectedTags;

      final updated = await api.updateArtist(_rawArtistJson!);
      ref.invalidate(lidarrArtistsProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artist updated'),
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
        ref.watch(lidarrQualityProfilesProvider(widget.instance));
    final metadataAsync =
        ref.watch(lidarrMetadataProfilesProvider(widget.instance));
    final tagsAsync = ref.watch(lidarrTagsProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Artist',
                style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            Text(widget.artist.artistName,
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monitored'),
                  subtitle: const Text(
                      'Lidarr will search for new albums by this artist'),
                  value: _monitored,
                  activeThumbColor: AppColors.tealPrimary,
                  onChanged: (v) => setState(() => _monitored = v),
                ),
                const SizedBox(height: Spacing.s16),

                profilesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading profiles: $e'),
                  data: (profiles) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Quality Profile',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: profiles.any(
                              (p) => p.id == _selectedQualityProfileId)
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

                metadataAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) =>
                      Text('Error loading metadata profiles: $e'),
                  data: (profiles) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Metadata Profile',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: profiles.any(
                              (p) => p.id == _selectedMetadataProfileId)
                          ? _selectedMetadataProfileId
                          : null,
                      items: profiles
                          .map((p) => DropdownMenuItem(
                              value: p.id, child: Text(p.name)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedMetadataProfileId = v),
                    );
                  },
                ),
                const SizedBox(height: Spacing.s16),

                TextFormField(
                  initialValue: _path,
                  decoration: const InputDecoration(
                    labelText: 'Path',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _path = v,
                ),
                const SizedBox(height: Spacing.s16),

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
