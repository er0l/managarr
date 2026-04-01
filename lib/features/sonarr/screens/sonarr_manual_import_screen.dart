import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../providers/sonarr_providers.dart';

class SonarrManualImportScreen extends ConsumerStatefulWidget {
  const SonarrManualImportScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SonarrManualImportScreen> createState() =>
      _SonarrManualImportScreenState();
}

class _SonarrManualImportScreenState
    extends ConsumerState<SonarrManualImportScreen> {
  String? _selectedFolder;
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  String? _error;
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    final rootFoldersAsync =
        ref.watch(sonarrRootFoldersProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Import'),
        actions: [
          if (_selectedIndices.isNotEmpty)
            FilledButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.download_done_outlined, size: 18),
              label: Text('Import ${_selectedIndices.length}'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: rootFoldersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load root folders: $e'),
              data: (folders) => InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Root Folder',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButton<String>(
                  value: _selectedFolder,
                  hint: const Text('Select a folder to scan'),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: folders
                      .map((f) => DropdownMenuItem(
                            value: f.path,
                            child: Text(f.path,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedFolder = v;
                        _selectedIndices.clear();
                      });
                      _scanFolder(v);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _scanFolder(_selectedFolder!),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_selectedFolder == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Select a root folder to scan for importable files',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('No importable files found in $_selectedFolder',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('${_items.length} file${_items.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  if (_selectedIndices.length == _items.length) {
                    _selectedIndices.clear();
                  } else {
                    _selectedIndices.addAll(
                        List.generate(_items.length, (i) => i));
                  }
                }),
                child: Text(_selectedIndices.length == _items.length
                    ? 'Deselect All'
                    : 'Select All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _ImportItemTile(
              item: _items[i],
              selected: _selectedIndices.contains(i),
              onToggle: () => setState(() {
                if (_selectedIndices.contains(i)) {
                  _selectedIndices.remove(i);
                } else {
                  _selectedIndices.add(i);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scanFolder(String folder) async {
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
      _selectedIndices.clear();
    });
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      final items = await api.getManualImport(folder);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to scan folder: $e';
        _loading = false;
      });
    }
  }

  Future<void> _import() async {
    if (_selectedIndices.isEmpty) return;
    final toImport = _selectedIndices.map((i) => _items[i]).toList();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.executeManualImport(toImport);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Importing ${toImport.length} file${toImport.length == 1 ? '' : 's'}…'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─── Import item tile ─────────────────────────────────────────────────────────

class _ImportItemTile extends StatelessWidget {
  const _ImportItemTile({
    required this.item,
    required this.selected,
    required this.onToggle,
  });

  final Map<String, dynamic> item;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = item['path'] as String? ?? '';
    final fileName = path.split('/').last.split(r'\').last;
    final series = item['series'] as Map<String, dynamic>?;
    final seriesTitle = series?['title'] as String?;
    final episodeNumbers = (item['episodes'] as List?)
        ?.map((e) =>
            'S${(e['seasonNumber'] as int).toString().padLeft(2, '0')}E${(e['episodeNumber'] as int).toString().padLeft(2, '0')}')
        .join(', ');
    final quality = (item['quality'] as Map<String, dynamic>?)?['quality']
        ?['name'] as String?;
    final rejections = item['rejections'] as List? ?? [];
    final hasRejections = rejections.isNotEmpty;

    return ListTile(
      leading: Checkbox(
        value: selected,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        seriesTitle != null && episodeNumbers != null
            ? '$seriesTitle — $episodeNumbers'
            : seriesTitle ?? fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (quality != null || hasRejections)
            Row(
              children: [
                if (quality != null)
                  Container(
                    margin: const EdgeInsets.only(top: 3, right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(quality,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                theme.colorScheme.onSecondaryContainer)),
                  ),
                if (hasRejections)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${rejections.length} rejection${rejections.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.red),
                    ),
                  ),
              ],
            ),
        ],
      ),
      isThreeLine: quality != null || hasRejections,
      onTap: onToggle,
    );
  }
}
