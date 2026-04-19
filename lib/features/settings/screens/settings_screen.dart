import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/instances_provider.dart';
import '../repositories/instance_repository.dart';
import '../services/image_cache_service.dart';
import '../widgets/instance_list_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(instancesByServiceProvider);
    final repo = ref.read(instanceRepositoryProvider);
    final serviceOrder = ServiceType.values;
    final populated = serviceOrder.where((t) => grouped.containsKey(t)).toList();

    return Scaffold(
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader(label: 'Appearance'),
          _ThemeSelector(),

          // ── Instances ───────────────────────────────────────────────────
          if (populated.isNotEmpty) _SectionHeader(label: 'Instances'),
          if (populated.isEmpty)
            _EmptyState(onAdd: () => context.push('/settings/add-instance'))
          else
            for (final type in populated) ...[
              _ServiceTypeHeader(type: type),
              for (final instance in grouped[type]!)
                InstanceListTile(
                  instance: instance,
                  onTap: () => context.push(
                    '/settings/edit-instance/${instance.id}',
                  ),
                  onDelete: () => _confirmDelete(
                    context,
                    name: instance.name,
                    onConfirm: () => repo.delete(instance.id),
                  ),
                ),
            ],

          // ── Storage ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Storage'),
          const _InMemoryCacheTile(),
          const _TempFilesTile(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/settings/add-instance'),
        backgroundColor: AppColors.orangeAccent,
        foregroundColor: AppColors.textOnPrimary,
        tooltip: 'Add Instance',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String name,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete instance'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusOffline,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }
}

// ---------------------------------------------------------------------------
// Theme selector widget
// ---------------------------------------------------------------------------

class _ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App Theme', style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          )),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (s) => notifier.setMode(s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.tealPrimary,
              selectedForegroundColor: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.tealPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _ServiceTypeHeader extends StatelessWidget {
  const _ServiceTypeHeader({required this.type});
  final ServiceType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        type.displayName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.tealPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// In-memory image cache tile
// ---------------------------------------------------------------------------

class _InMemoryCacheTile extends StatefulWidget {
  const _InMemoryCacheTile();

  @override
  State<_InMemoryCacheTile> createState() => _InMemoryCacheTileState();
}

class _InMemoryCacheTileState extends State<_InMemoryCacheTile> {
  void _clear() {
    ImageCacheService.clearInMemoryCache();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image cache cleared'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = ImageCacheService.getInMemoryInfo();
    final theme = Theme.of(context);

    final subtitle = info.isEmpty
        ? 'Empty'
        : '${ImageCacheService.formatBytes(info.sizeBytes)}'
            ' · ${info.imageCount} image${info.imageCount == 1 ? '' : 's'} loaded';

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.tealPrimary.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          size: 20,
          color: AppColors.tealPrimary,
        ),
      ),
      title: Text('Image cache', style: theme.textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: TextButton(
        onPressed: info.isEmpty ? null : _clear,
        child: const Text('Clear'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Temporary files tile
// ---------------------------------------------------------------------------

class _TempFilesTile extends StatefulWidget {
  const _TempFilesTile();

  @override
  State<_TempFilesTile> createState() => _TempFilesTileState();
}

class _TempFilesTileState extends State<_TempFilesTile> {
  late Future<int> _sizeFuture;

  @override
  void initState() {
    super.initState();
    _sizeFuture = ImageCacheService.getTempDirSize();
  }

  Future<void> _clear() async {
    await ImageCacheService.clearTempDir();
    if (!mounted) return;
    setState(() {
      _sizeFuture = ImageCacheService.getTempDirSize();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Temporary files cleared'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<int>(
      future: _sizeFuture,
      builder: (context, snap) {
        final loading = !snap.hasData && !snap.hasError;
        final bytes = snap.data ?? 0;
        final empty = bytes == 0;

        final subtitle = loading
            ? 'Calculating…'
            : empty
                ? 'Empty'
                : ImageCacheService.formatBytes(bytes);

        return ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tealPrimary.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.folder_open_outlined,
              size: 20,
              color: AppColors.tealPrimary,
            ),
          ),
          title: Text('Temporary files', style: theme.textTheme.bodyLarge),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.tealPrimary,
                  ),
                )
              : TextButton(
                  onPressed: empty ? null : _clear,
                  child: const Text('Clear'),
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 64,
              color: AppColors.textSecondary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No instances yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a service instance to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orangeAccent,
                foregroundColor: AppColors.textOnPrimary,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Instance'),
            ),
          ],
        ),
      ),
    );
  }
}
