import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/service_detail_shell.dart';
import 'prowlarr_add_indexer_screen.dart';
import 'prowlarr_history_screen.dart';
import 'prowlarr_indexers_screen.dart';
import 'prowlarr_search_screen.dart';

class ProwlarrHomeScreen extends StatelessWidget {
  const ProwlarrHomeScreen({super.key, required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context) => ServiceDetailShell(
    instance: instance,
    serviceName: 'Prowlarr',
    sections: [
      ServiceSection(
        label: 'Search',
        icon: Icons.search,
        body: ProwlarrSearchScreen(instance: instance),
      ),
      ServiceSection(
        label: 'Indexers',
        icon: Icons.dns_outlined,
        body: ProwlarrIndexersScreen(instance: instance),
        action: FilledButton.tonalIcon(
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProwlarrAddIndexerScreen(instance: instance),
            ),
          ),
        ),
      ),
      ServiceSection(
        label: 'History',
        icon: Icons.history,
        body: ProwlarrHistoryScreen(instance: instance),
      ),
    ],
  );
}
