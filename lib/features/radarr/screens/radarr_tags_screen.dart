import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/radarr_providers.dart';

class RadarrTagsScreen extends ConsumerWidget {
  const RadarrTagsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(radarrTagsProvider(instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text('Tags',
            style: TextStyle(color: AppColors.textOnPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
            tooltip: 'Add Tag',
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: tagsAsync.when(
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
                onPressed: () => ref.invalidate(radarrTagsProvider(instance)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.label_off_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('No tags yet'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tag'),
                    onPressed: () => _showAddDialog(context, ref),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(radarrTagsProvider(instance)),
            color: AppColors.tealPrimary,
            child: ListView.separated(
              itemCount: tags.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final tag = tags[i];
                return ListTile(
                  leading: const Icon(Icons.label_outline,
                      color: AppColors.tealPrimary),
                  title: Text(tag.label),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.statusOffline, size: 20),
                    onPressed: () => _confirmDelete(context, ref, tag.id, tag.label),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tag label',
            labelText: 'Label',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _createTag(ctx, ref, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _createTag(ctx, ref, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTag(
      BuildContext context, WidgetRef ref, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context);
    try {
      final api = ref.read(radarrApiProvider(instance));
      await api.createTag(trimmed);
      ref.invalidate(radarrTagsProvider(instance));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create tag: $e'),
          backgroundColor: AppColors.statusOffline,
        ));
      }
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, int id, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Delete tag "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(radarrApiProvider(instance));
                await api.deleteTag(id);
                ref.invalidate(radarrTagsProvider(instance));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to delete tag: $e'),
                    backgroundColor: AppColors.statusOffline,
                  ));
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.statusOffline)),
          ),
        ],
      ),
    );
  }
}
