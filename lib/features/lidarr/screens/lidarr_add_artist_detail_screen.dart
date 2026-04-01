import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/artist.dart';
import '../providers/lidarr_providers.dart';

class LidarrAddArtistDetailScreen extends ConsumerStatefulWidget {
  const LidarrAddArtistDetailScreen({
    super.key,
    required this.artist,
    required this.instance,
  });

  final LidarrArtist artist;
  final Instance instance;

  @override
  ConsumerState<LidarrAddArtistDetailScreen> createState() =>
      _LidarrAddArtistDetailScreenState();
}

class _LidarrAddArtistDetailScreenState
    extends ConsumerState<LidarrAddArtistDetailScreen> {
  int? _selectedQualityProfileId;
  int? _selectedMetadataProfileId;
  String? _selectedRootFolder;
  bool _monitored = true;
  bool _searchOnAdd = true;
  bool _adding = false;

  static const _monitorOptions = {
    'all': 'All Albums',
    'future': 'Future Albums',
    'missing': 'Missing Albums',
    'existing': 'Existing Albums',
    'first': 'First Album',
    'latest': 'Latest Album',
    'none': 'None',
  };

  String _selectedMonitor = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profilesAsync =
        ref.watch(lidarrQualityProfilesProvider(widget.instance));
    final metadataAsync =
        ref.watch(lidarrMetadataProfilesProvider(widget.instance));
    final rootFoldersAsync =
        ref.watch(lidarrRootFoldersProvider(widget.instance));
    final fanart = widget.artist.fanartUrl;
    final poster = widget.artist.posterUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Artist',
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
                if (poster != null)
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
                      child: Image.network(poster, fit: BoxFit.cover),
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
                if (widget.artist.overview != null &&
                    widget.artist.overview!.isNotEmpty) ...[
                  Text(
                    widget.artist.overview!,
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

                // Metadata Profile
                metadataAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading metadata profiles: $e'),
                  data: (profiles) {
                    _selectedMetadataProfileId ??=
                        profiles.isNotEmpty ? profiles.first.id : null;
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

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monitored'),
                  subtitle: const Text('Lidarr will search for new albums'),
                  value: _monitored,
                  activeThumbColor: AppColors.tealPrimary,
                  onChanged: (v) => setState(() => _monitored = v),
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Search on Add'),
                  subtitle:
                      const Text('Immediately search for missing albums'),
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
                          borderRadius: BorderRadius.circular(12)),
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
                    label: const Text('Add Artist',
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
      _selectedQualityProfileId != null &&
      _selectedMetadataProfileId != null &&
      _selectedRootFolder != null;

  Future<void> _add() async {
    setState(() => _adding = true);
    try {
      final api = ref.read(lidarrApiProvider(widget.instance));
      final data = <String, dynamic>{
        'artistName': widget.artist.artistName,
        'foreignArtistId': widget.artist.foreignArtistId,
        'qualityProfileId': _selectedQualityProfileId,
        'metadataProfileId': _selectedMetadataProfileId,
        'rootFolderPath': _selectedRootFolder,
        'monitored': _monitored,
        'addOptions': {
          'monitor': _selectedMonitor,
          'searchForMissingAlbums': _searchOnAdd,
        },
      };
      await api.addArtist(data);
      ref.invalidate(lidarrArtistsProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('"${widget.artist.artistName}" added to Lidarr'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding artist: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _adding = false);
      }
    }
  }
}
