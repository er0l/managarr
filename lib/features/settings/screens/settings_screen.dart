import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/instances_provider.dart';
import '../repositories/instance_repository.dart';
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
