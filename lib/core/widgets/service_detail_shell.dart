import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/models/service_type.dart';
import '../network/dio_client.dart';
import 'app_drawer.dart';
import 'module_app_bar.dart';
import 'service_avatar.dart';

class ServiceSection {
  const ServiceSection({
    required this.label,
    required this.icon,
    required this.body,
    this.title,
    this.action,
    this.toolbar,
  });
  final String label;
  final String? title;
  final IconData icon;
  final Widget body;
  final Widget? action;
  final Widget? toolbar;
}

/// Stable section navigation. Sections mount on first visit and preserve state.
class ServiceDetailShell extends ConsumerStatefulWidget {
  const ServiceDetailShell({
    super.key,
    required this.instance,
    required this.serviceName,
    required this.sections,
    this.moreItems = const [],
    this.onMoreSelected,
  }) : assert(sections.length > 0 && sections.length <= 3);
  final Instance instance;
  final String serviceName;
  final List<ServiceSection> sections;
  final List<PopupMenuEntry<String>> moreItems;
  final ValueChanged<String>? onMoreSelected;

  @override
  ConsumerState<ServiceDetailShell> createState() => _ServiceDetailShellState();
}

class _ServiceDetailShellState extends ConsumerState<ServiceDetailShell> {
  int _selected = 0;
  final _visited = <int>{0};

  @override
  void didUpdateWidget(covariant ServiceDetailShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance.id != widget.instance.id) {
      _selected = 0;
      _visited
        ..clear()
        ..add(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = ServiceType.values.byName(widget.instance.serviceType);
    final hasLocal = widget.instance.localUrl?.isNotEmpty ?? false;
    final useLocal = hasLocal
        ? ref.watch(useLocalUrlProvider(widget.instance.id))
        : false;
    final sections = [
      ...widget.sections,
      ServiceSection(
        label: 'More',
        icon: Icons.more_horiz,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (widget.moreItems.isNotEmpty) ...[
              const _GroupLabel('Manage'),
              for (final entry in widget.moreItems)
                if (entry is PopupMenuDivider)
                  const Divider()
                else if (entry is PopupMenuItem<String>)
                  _MoreTile(
                    entry: entry,
                    onTap: () => widget.onMoreSelected?.call(entry.value!),
                  ),
            ],
            const _GroupLabel('Connection'),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(widget.instance.name),
              subtitle: Text(
                useLocal ? 'Local connection' : 'Remote connection',
              ),
            ),
            if (hasLocal)
              SwitchListTile(
                secondary: const Icon(Icons.lan_outlined),
                title: const Text('Use local connection'),
                value: useLocal,
                onChanged: (value) =>
                    ref
                            .read(
                              useLocalUrlProvider(widget.instance.id).notifier,
                            )
                            .state =
                        value,
              ),
          ],
        ),
      ),
    ];
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: ModuleAppBar(
        toolbarHeight: 72,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Switch module or instance',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            ServiceAvatar(type: type, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.instance.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          key: ValueKey(widget.instance.id),
          index: _selected,
          children: [
            for (var i = 0; i < sections.length; i++)
              if (_visited.contains(i))
                TickerMode(
                  enabled: i == _selected,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sections[i].title ?? sections[i].label,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (sections[i].action != null) sections[i].action!,
                          ],
                        ),
                      ),
                      if (sections[i].toolbar != null) sections[i].toolbar!,
                      Expanded(child: sections[i].body),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colors.primaryContainer,
        onDestinationSelected: (index) => setState(() {
          _selected = index;
          _visited.add(index);
        }),
        destinations: [
          for (final section in sections)
            NavigationDestination(
              icon: Icon(section.icon),
              label: section.label,
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.entry, required this.onTap});
  final PopupMenuItem<String> entry;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final child = entry.child;
    return ListTile(
      leading: child is ListTile ? child.leading : null,
      title: child is ListTile ? child.title : child,
      subtitle: child is ListTile ? child.subtitle : null,
      trailing: const Icon(Icons.chevron_right),
      enabled: entry.enabled,
      onTap: entry.value == null ? null : onTap,
    );
  }
}

class ServiceToolbar extends StatelessWidget {
  const ServiceToolbar({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Wrap(spacing: 4, runSpacing: 4, children: children),
  );
}
