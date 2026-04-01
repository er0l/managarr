import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/series.dart';
import '../providers/sonarr_providers.dart';

class SonarrAddSeriesDetailScreen extends ConsumerStatefulWidget {
  const SonarrAddSeriesDetailScreen({
    super.key,
    required this.series,
    required this.instance,
  });

  final SonarrSeries series;
  final Instance instance;

  @override
  ConsumerState<SonarrAddSeriesDetailScreen> createState() =>
      _SonarrAddSeriesDetailScreenState();
}

class _SonarrAddSeriesDetailScreenState
    extends ConsumerState<SonarrAddSeriesDetailScreen> {
  int? _selectedQualityProfileId;
  String? _selectedRootFolder;
  String _selectedSeriesType = 'standard';
  bool _monitored = true;
  bool _searchOnAdd = true;
  bool _adding = false;

  static const _seriesTypeOptions = {
    'standard': 'Standard',
    'daily': 'Daily',
    'anime': 'Anime',
  };

  static const _monitorOptions = {
    'all': 'All Episodes',
    'future': 'Future Episodes',
    'missing': 'Missing Episodes',
    'existing': 'Existing Episodes',
    'first': 'First Season',
    'latest': 'Latest Season',
    'none': 'None',
  };

  String _selectedMonitor = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profilesAsync =
        ref.watch(sonarrQualityProfilesProvider(widget.instance));
    final rootFoldersAsync =
        ref.watch(sonarrRootFoldersProvider(widget.instance));
    final fanart = widget.series.fanartUrl;
    final poster = widget.series.posterUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Series',
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
          if (_adding)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textOnPrimary),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
              tooltip: 'Add',
              onPressed: _canAdd() ? _add : null,
            ),
        ],
      ),
      body: ListView(
        children: [
          // Backdrop header
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (fanart != null)
                  Image.network(fanart, fit: BoxFit.cover)
                else
                  Container(color: AppColors.tealDark),
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
                  bottom: 12,
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
                if (widget.series.year != null)
                  Positioned(
                    bottom: 18,
                    left: 88,
                    child: Text(
                      '${widget.series.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(Spacing.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview
                if (widget.series.overview != null &&
                    widget.series.overview!.isNotEmpty) ...[
                  Text(
                    widget.series.overview!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.s24),
                ],

                // Quality Profile
                profilesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading profiles: $e'),
                  data: (profiles) {
                    _selectedQualityProfileId ??=
                        profiles.isNotEmpty ? profiles.first.id : null;
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

                // Root Folder
                rootFoldersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading root folders: $e'),
                  data: (folders) {
                    _selectedRootFolder ??=
                        folders.isNotEmpty ? folders.first.path : null;
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Root Folder',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: folders.any(
                              (f) => f.path == _selectedRootFolder)
                          ? _selectedRootFolder
                          : null,
                      items: folders
                          .map((f) => DropdownMenuItem(
                              value: f.path, child: Text(f.path)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRootFolder = v),
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
                  initialValue: _selectedSeriesType,
                  items: _seriesTypeOptions.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSeriesType = v);
                  },
                ),
                const SizedBox(height: Spacing.s16),

                // Monitor
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Monitor',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedMonitor,
                  items: _monitorOptions.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedMonitor = v);
                  },
                ),
                const SizedBox(height: Spacing.s16),

                // Monitored toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monitored'),
                  subtitle: const Text('Sonarr will search for new episodes'),
                  value: _monitored,
                  activeThumbColor: AppColors.tealPrimary,
                  onChanged: (v) => setState(() => _monitored = v),
                ),

                // Search on add
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Search on Add'),
                  subtitle: const Text('Immediately search for episodes'),
                  value: _searchOnAdd,
                  activeThumbColor: AppColors.tealPrimary,
                  onChanged: (v) => setState(() => _searchOnAdd = v),
                ),

                const SizedBox(height: Spacing.s24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _canAdd() && !_adding ? _add : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding:
                          const EdgeInsets.symmetric(vertical: Spacing.s16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _adding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add Series',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: Spacing.s48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canAdd() =>
      _selectedQualityProfileId != null && _selectedRootFolder != null;

  Future<void> _add() async {
    setState(() => _adding = true);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      final data = <String, dynamic>{
        'title': widget.series.title,
        'tvdbId': widget.series.tvdbId,
        'qualityProfileId': _selectedQualityProfileId,
        'rootFolderPath': _selectedRootFolder,
        'seriesType': _selectedSeriesType,
        'monitored': _monitored,
        'seasons': widget.series.seasons?.map((s) => s.toJson()).toList() ?? [],
        'addOptions': {
          'monitor': _selectedMonitor,
          'searchForMissingEpisodes': _searchOnAdd,
        },
      };
      await api.addSeries(data);
      ref.invalidate(sonarrSeriesProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.series.title}" added to Sonarr'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop back to the home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding series: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _adding = false);
      }
    }
  }
}
