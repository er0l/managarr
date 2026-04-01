import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/rtorrent_api.dart';
import '../providers/rtorrent_providers.dart';
import '../widgets/torrent_tile.dart';
import 'rtorrent_torrent_detail_screen.dart';

class RTorrentHomeScreen extends ConsumerStatefulWidget {
  const RTorrentHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<RTorrentHomeScreen> createState() =>
      _RTorrentHomeScreenState();
}

class _RTorrentHomeScreenState extends ConsumerState<RTorrentHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final torrentsAsync =
        ref.watch(rtorrentTorrentsProvider(widget.instance));
    final filtered = ref.watch(rtorrentFilteredProvider(widget.instance));
    final stats = ref.watch(rtorrentGlobalStatsProvider(widget.instance));

    // Watch sort/filter providers to rebuild when they change.
    ref.watch(rtorrentSortProvider(widget.instance.id));
    ref.watch(rtorrentStatusFilterProvider(widget.instance.id));
    ref.watch(rtorrentLabelFilterProvider(widget.instance.id));

    // Unique labels from raw list
    final labels = torrentsAsync.when(
      data: (t) => t
          .map((x) => x.label)
          .where((l) => l.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
      loading: () => <String>[],
      error: (e, s) => <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        title: Text(
          widget.instance.name,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orangeAccent,
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _GlobalStatsHeader(stats: stats),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search torrents…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: ref.watch(rtorrentSearchQueryProvider(widget.instance.id)).isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(rtorrentSearchQueryProvider(widget.instance.id).notifier).state = '';
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => ref
                        .read(rtorrentSearchQueryProvider(widget.instance.id).notifier)
                        .state = v,
                  ),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.filter_list,
                  onTap: () => _showFilterSheet(context, labels),
                ),
                const SizedBox(width: 4),
                _ControlButton(
                  icon: Icons.sort,
                  onTap: () => _showSortSheet(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: torrentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('$e'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(
                          rtorrentTorrentsProvider(widget.instance)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return const Center(child: Text('No torrents'));
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(rtorrentTorrentsProvider(widget.instance)),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => TorrentTile(
                      torrent: filtered[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RTorrentTorrentDetailScreen(
                            instance: widget.instance,
                            torrent: filtered[i],
                            onRefresh: () async => ref.invalidate(
                                rtorrentTorrentsProvider(widget.instance)),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Add by URL'),
            onTap: () {
              Navigator.pop(ctx);
              _showAddByUrlDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Add from File'),
            onTap: () {
              Navigator.pop(ctx);
              _addByFile();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _addByFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['torrent'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        final api = RTorrentApi.fromInstance(widget.instance);
        final ok = await api.addByFile(result.files.single.bytes!);
        _showStatus(messenger, ok, 'Torrent added from file');
        if (ok) {
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(rtorrentTorrentsProvider(widget.instance));
        }
      } catch (e) {
        _showError(messenger, e);
      }
    }
  }

  void _showStatus(ScaffoldMessengerState s, bool ok, String msg) {
    s.showSnackBar(SnackBar(
      content: Text(ok ? msg : 'Action failed'),
      backgroundColor: ok ? AppColors.statusOnline : AppColors.statusOffline,
    ));
  }

  void _showError(ScaffoldMessengerState s, dynamic e) {
    s.showSnackBar(SnackBar(
      content: Text('Error: $e'),
      backgroundColor: AppColors.statusOffline,
    ));
  }

  void _showSortSheet(BuildContext context) {
    final current =
        ref.read(rtorrentSortProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (_) {
        final options = [
          (RTorrentSort.name, 'Name', Icons.sort_by_alpha),
          (RTorrentSort.status, 'Status', Icons.info_outline),
          (RTorrentSort.size, 'Size', Icons.storage),
          (RTorrentSort.dateAdded, 'Date Added', Icons.add_circle_outline),
          (RTorrentSort.dateDone, 'Date Done', Icons.done_all),
          (RTorrentSort.percentDownloaded, 'Percent Downloaded', Icons.percent),
          (RTorrentSort.downloadSpeed, 'Download Speed', Icons.arrow_downward),
          (RTorrentSort.uploadSpeed, 'Upload Speed', Icons.arrow_upward),
          (RTorrentSort.ratio, 'Ratio', Icons.compare_arrows),
        ];
        return ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold))),
            ...options.map(
              (o) => ListTile(
                leading: Icon(o.$3),
                title: Text(o.$2),
                trailing: current == o.$1
                    ? const Icon(Icons.check, color: AppColors.tealPrimary)
                    : null,
                onTap: () {
                  ref
                      .read(rtorrentSortProvider(widget.instance.id).notifier)
                      .state = o.$1;
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, List<String> labels) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final statusFilter =
              ref.read(rtorrentStatusFilterProvider(widget.instance.id));
          final labelFilter =
              ref.read(rtorrentLabelFilterProvider(widget.instance.id));

          return ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                  title: Text('Filter by Status',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...RTorrentStatusFilter.values.map((f) => ListTile(
                    title: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                    trailing: statusFilter == f
                        ? const Icon(Icons.check, color: AppColors.tealPrimary)
                        : null,
                    onTap: () {
                      ref
                          .read(rtorrentStatusFilterProvider(
                                  widget.instance.id)
                              .notifier)
                          .state = f;
                      Navigator.pop(context);
                    },
                  )),
              if (labels.isNotEmpty) ...[
                const ListTile(
                    title: Text('Filter by Label',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                ListTile(
                  title: const Text('All Labels'),
                  trailing: labelFilter.isEmpty
                      ? const Icon(Icons.check, color: AppColors.tealPrimary)
                      : null,
                  onTap: () {
                    ref
                        .read(rtorrentLabelFilterProvider(widget.instance.id)
                            .notifier)
                        .state = '';
                    Navigator.pop(context);
                  },
                ),
                ...labels.map((l) => ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(l),
                      trailing: labelFilter == l
                          ? const Icon(Icons.check,
                              color: AppColors.tealPrimary)
                          : null,
                      onTap: () {
                        ref
                            .read(rtorrentLabelFilterProvider(
                                    widget.instance.id)
                                .notifier)
                            .state = l;
                        Navigator.pop(context);
                      },
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddByUrlDialog(BuildContext context) async {
    final urlController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Torrent by URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'http:// or magnet:',
            labelText: 'URL',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final url = urlController.text.trim();
              Navigator.pop(ctx);
              if (url.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final api = RTorrentApi.fromInstance(widget.instance);
                final ok = await api.addByUrl(url);
                _showStatus(messenger, ok, 'Torrent added');
                if (ok) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  ref.invalidate(rtorrentTorrentsProvider(widget.instance));
                }
              } catch (e) {
                _showError(messenger, e);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      iconSize: 20,
      icon: Icon(icon),
    );
  }
}

class _GlobalStatsHeader extends StatelessWidget {
  const _GlobalStatsHeader({required this.stats});
  final RTorrentGlobalStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(30),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primaryContainer.withAlpha(50),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.arrow_downward,
            value: '${_fmt(stats.totalDownRate)}/s',
            label: 'Download',
            color: AppColors.statusOnline,
          ),
          _StatItem(
            icon: Icons.arrow_upward,
            value: '${_fmt(stats.totalUpRate)}/s',
            label: 'Upload',
            color: AppColors.blueAccent,
          ),
          _StatItem(
            icon: Icons.layers_outlined,
            value: stats.totalTorrents.toString(),
            label: 'Total',
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _fmt(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double val = bytes.toDouble();
    while (val >= 1024 && i < units.length - 1) {
      val /= 1024;
      i++;
    }
    return '${val.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                )),
          ],
        ),
        Text(label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            )),
      ],
    );
  }
}
