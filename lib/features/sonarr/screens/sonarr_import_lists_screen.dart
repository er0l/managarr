import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/import_list.dart';
import '../providers/sonarr_providers.dart';

class SonarrImportListsScreen extends ConsumerWidget {
  const SonarrImportListsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(sonarrImportListsProvider(instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text('Import Lists',
            style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.statusOffline),
              const SizedBox(height: 12),
              Text('$e'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(sonarrImportListsProvider(instance)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (lists) {
          if (lists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_outlined,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No import lists configured'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(sonarrImportListsProvider(instance)),
            color: AppColors.tealPrimary,
            child: ListView.separated(
              itemCount: lists.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) => _ImportListTile(
                list: lists[i],
                instance: instance,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImportListTile extends ConsumerWidget {
  const _ImportListTile({required this.list, required this.instance});

  final SonarrImportList list;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (list.enabled ? AppColors.tealPrimary : AppColors.statusUnknown)
              .withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.list_alt_outlined,
          size: 20,
          color:
              list.enabled ? AppColors.tealPrimary : AppColors.statusUnknown,
        ),
      ),
      title: Text(
        list.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: list.enabled ? null : AppColors.textSecondary,
            ),
      ),
      subtitle: Text(
        list.listType,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: list.enabled,
        activeThumbColor: AppColors.tealPrimary,
        onChanged: (value) => _toggle(context, ref, value),
      ),
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, bool enabled) async {
    final api = ref.read(sonarrApiProvider(instance));
    try {
      await api.toggleImportList(list, enabled);
      ref.invalidate(sonarrImportListsProvider(instance));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update import list: $e'),
          backgroundColor: AppColors.statusOffline,
        ));
      }
    }
  }
}
