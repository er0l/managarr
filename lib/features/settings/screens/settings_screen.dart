import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/service_avatar.dart';
import '../providers/instances_provider.dart';
import '../providers/ui_prefs_provider.dart';
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
    final populated =
        serviceOrder.where((t) => grouped.containsKey(t)).toList();

    return Scaffold(
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          const SectionHeader(title: 'Appearance'),
          const _SettingsCard(children: [
            _ThemeSelector(),
            Divider(height: 1),
            _GridColumnsSelector(),
          ]),

          // ── Instances ───────────────────────────────────────────────────
          if (populated.isNotEmpty) const SectionHeader(title: 'Instances'),
          if (populated.isEmpty)
            _EmptyState(onAdd: () => context.push('/settings/add-instance'))
          else
            for (final type in populated)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.cardGap),
                child: _SettingsCard(
                  children: [
                    _ServiceGroupHeader(type: type),
                    for (final instance in grouped[type]!) ...[
                      const Divider(height: 1, indent: 60),
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
                  ],
                ),
              ),

          // ── Storage ─────────────────────────────────────────────────────
          const SectionHeader(title: 'Storage'),
          const _SettingsCard(
            children: [
              _InMemoryCacheTile(),
              Divider(height: 1, indent: 60),
              _TempFilesTile(),
            ],
          ),
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
// Grouped settings card — rounded bordered card containing a column of tiles.
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ServiceGroupHeader extends StatelessWidget {
  const _ServiceGroupHeader({required this.type});

  final ServiceType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          ServiceAvatar(type: type, size: 28),
          const SizedBox(width: Spacing.s12),
          Text(
            type.displayName,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme selector widget
// ---------------------------------------------------------------------------

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Theme',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
// Grid columns selector
// ---------------------------------------------------------------------------

class _GridColumnsSelector extends ConsumerWidget {
  const _GridColumnsSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(gridColumnsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library grid columns',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 2,
                icon: Icon(Icons.grid_view_outlined),
                label: Text('2 per row'),
              ),
              ButtonSegment(
                value: 3,
                icon: Icon(Icons.grid_on_outlined),
                label: Text('3 per row'),
              ),
            ],
            selected: {columns},
            onSelectionChanged: (s) =>
                ref.read(gridColumnsProvider.notifier).setColumns(s.first),
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
          color: theme.colorScheme.onSurfaceVariant,
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
              color: theme.colorScheme.onSurfaceVariant,
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
