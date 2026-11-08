import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/module_app_bar.dart';
import '../../../core/widgets/service_avatar.dart';
import '../providers/drawer_order_provider.dart';
import '../providers/instances_provider.dart';

class DrawerSettingsScreen extends ConsumerWidget {
  const DrawerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(drawerOrderProvider);
    final instances = ref.watch(instancesByServiceProvider);
    final notifier = ref.read(drawerOrderProvider.notifier);
    return Scaffold(
      appBar: ModuleAppBar(
        title: const Text('Drawer'),
        actions: [
          TextButton(onPressed: notifier.reset, child: const Text('Reset')),
        ],
      ),
      body: ReorderableListView.builder(
        header: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Drag the handles to reorder modules. Only configured modules appear '
            'in the drawer. Dashboard stays at the top.',
          ),
        ),
        buildDefaultDragHandles: false,
        itemCount: order.length,
        onReorder: notifier.reorder,
        itemBuilder: (context, index) {
          final type = order[index];
          final count = instances[type]?.length ?? 0;
          return ListTile(
            key: ValueKey(type),
            leading: ServiceAvatar(type: type, size: 32),
            title: Text(type.displayName),
            subtitle: Text(count == 0 ? 'Not configured' : '$count configured'),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.drag_handle,
                  semanticLabel: 'Drag to reorder',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
