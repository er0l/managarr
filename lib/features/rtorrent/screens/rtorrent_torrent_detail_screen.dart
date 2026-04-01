import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/torrent.dart';
import '../api/rtorrent_api.dart';

// Per-torrent trackers/files providers
final _trackersProvider =
    FutureProvider.autoDispose.family<List<RTorrentTracker>, ({Instance instance, String hash})>(
        (ref, key) async {
  final api = RTorrentApi.fromInstance(key.instance);
  return api.getTrackers(key.hash);
});

final _filesProvider =
    FutureProvider.autoDispose.family<List<RTorrentFile>, ({Instance instance, String hash})>(
        (ref, key) async {
  final api = RTorrentApi.fromInstance(key.instance);
  return api.getFiles(key.hash);
});

class RTorrentTorrentDetailScreen extends ConsumerStatefulWidget {
  const RTorrentTorrentDetailScreen({
    super.key,
    required this.instance,
    required this.torrent,
    required this.onRefresh,
  });

  final Instance instance;
  final RTorrentTorrent torrent;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<RTorrentTorrentDetailScreen> createState() =>
      _RTorrentTorrentDetailScreenState();
}

class _RTorrentTorrentDetailScreenState
    extends ConsumerState<RTorrentTorrentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _action(Future<bool> Function() fn, String successMsg) async {
    try {
      final ok = await fn();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? successMsg : 'Action failed'),
          backgroundColor: ok ? AppColors.statusOnline : AppColors.statusOffline,
        ),
      );
      if (ok) await widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusOffline),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.torrent;
    final api = RTorrentApi.fromInstance(widget.instance);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Text(
          t.name,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withAlpha(160),
          indicatorColor: AppColors.orangeAccent,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Trackers'),
            Tab(text: 'Files'),
          ],
        ),
        actions: [
          PopupMenuButton<_TorrentAction>(
            icon: const Icon(Icons.more_vert, color: AppColors.textOnPrimary),
            onSelected: (action) => switch (action) {
              _TorrentAction.resume => _action(
                  () => api.resume(t.hash), 'Torrent resumed'),
              _TorrentAction.pause => _action(
                  () => api.pause(t.hash), 'Torrent paused'),
              _TorrentAction.stop => _action(
                  () => api.stop(t.hash), 'Torrent stopped'),
              _TorrentAction.check => _action(
                  () => api.checkHash(t.hash), 'Hash check started'),
              _TorrentAction.setLabel => _showEditLabelDialog(api),
              _TorrentAction.remove => _showRemoveDialog(api),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: _TorrentAction.resume,
                  child: ListTile(
                      leading: Icon(Icons.play_arrow),
                      title: Text('Resume'))),
              const PopupMenuItem(
                  value: _TorrentAction.pause,
                  child: ListTile(
                      leading: Icon(Icons.pause),
                      title: Text('Pause'))),
              const PopupMenuItem(
                  value: _TorrentAction.stop,
                  child: ListTile(
                      leading: Icon(Icons.stop),
                      title: Text('Stop'))),
              const PopupMenuItem(
                  value: _TorrentAction.check,
                  child: ListTile(
                      leading: Icon(Icons.verified_outlined),
                      title: Text('Check Hash'))),
              const PopupMenuItem(
                  value: _TorrentAction.setLabel,
                  child: ListTile(
                      leading: Icon(Icons.label_outline),
                      title: Text('Set Label'))),
              const PopupMenuItem(
                  value: _TorrentAction.remove,
                  child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: Colors.red),
                      title: Text('Remove',
                          style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(torrent: t),
          _TrackersTab(instance: widget.instance, hash: t.hash),
          _FilesTab(instance: widget.instance, hash: t.hash),
        ],
      ),
    );
  }

  Future<void> _showEditLabelDialog(RTorrentApi api) async {
    final controller = TextEditingController(text: widget.torrent.label);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Torrent Label'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter label name',
            labelText: 'Label',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _action(
        () => api.setLabel(widget.torrent.hash, controller.text.trim()),
        'Label updated',
      );
    }
  }

  Future<void> _showRemoveDialog(RTorrentApi api) async {
    bool deleteData = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Remove Torrent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Remove this torrent from rTorrent?'),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Delete data'),
                value: deleteData,
                onChanged: (v) => setState(() => deleteData = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _action(
        () => api.remove(widget.torrent.hash, deleteData: deleteData),
        'Torrent removed',
      );
      if (mounted) Navigator.of(context).pop();
    }
  }
}

enum _TorrentAction { resume, pause, stop, check, setLabel, remove }

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.torrent});
  final RTorrentTorrent torrent;

  @override
  Widget build(BuildContext context) {
    final t = torrent;
    final color = t.isError
        ? AppColors.statusOffline
        : t.isSeeding
            ? AppColors.blueAccent
            : t.isDownloading
                ? AppColors.statusOnline
                : t.isPaused
                    ? AppColors.statusWarning
                    : AppColors.statusUnknown;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: t.percentageDone / 100.0,
            minHeight: 8,
            backgroundColor: color.withAlpha(40),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 16),
        _Row('Status', t.statusLabel),
        _Row('Progress', '${t.percentageDone}%'),
        _Row('Size', _fmt(t.size)),
        _Row('Downloaded', _fmt(t.completed)),
        _Row('Ratio', t.ratio.toStringAsFixed(3)),
        if (t.downRate > 0) _Row('Down Speed', '${_fmt(t.downRate)}/s'),
        if (t.upRate > 0) _Row('Up Speed', '${_fmt(t.upRate)}/s'),
        _Row('Label', t.label.isEmpty ? '(none)' : t.label),
        if (t.dateAdded > 0)
          _Row('Added',
              DateTime.fromMillisecondsSinceEpoch(t.dateAdded * 1000)
                  .toLocal()
                  .toString()
                  .substring(0, 19)),
        if (t.dateDone > 0)
          _Row('Finished',
              DateTime.fromMillisecondsSinceEpoch(t.dateDone * 1000)
                  .toLocal()
                  .toString()
                  .substring(0, 19)),
        _Row('Hash', t.hash),
        if (t.isError)
          _Row('Error', t.message, valueColor: AppColors.statusOffline),
      ],
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500, color: valueColor)),
          ),
        ],
      ),
    );
  }
}

class _TrackersTab extends ConsumerWidget {
  const _TrackersTab({required this.instance, required this.hash});
  final Instance instance;
  final String hash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(_trackersProvider((instance: instance, hash: hash)));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (trackers) {
        if (trackers.isEmpty) {
          return const Center(child: Text('No trackers'));
        }
        return ListView.separated(
          itemCount: trackers.length,
          separatorBuilder: (_, i) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final tr = trackers[i];
            return ListTile(
              leading: const Icon(Icons.track_changes_outlined),
              title: Text(tr.url,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
              subtitle: Text('Type ${tr.type}',
                  style: const TextStyle(fontSize: 11)),
            );
          },
        );
      },
    );
  }
}

class _FilesTab extends ConsumerWidget {
  const _FilesTab({required this.instance, required this.hash});
  final Instance instance;
  final String hash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_filesProvider((instance: instance, hash: hash)));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (files) {
        if (files.isEmpty) {
          return const Center(child: Text('No files'));
        }
        return ListView.separated(
          itemCount: files.length,
          separatorBuilder: (_, i) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final f = files[i];
            return ListTile(
              leading: Icon(
                f.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.hourglass_bottom_outlined,
                color: f.isCompleted
                    ? AppColors.statusOnline
                    : AppColors.statusWarning,
              ),
              title: Text(f.path.split('/').last,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${f.percentageDone}%  •  ${_fmt(f.size)}'),
            );
          },
        );
      },
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
