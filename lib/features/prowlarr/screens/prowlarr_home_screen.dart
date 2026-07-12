import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_bar_button.dart';
import '../../../core/widgets/service_detail_shell.dart';
import 'prowlarr_add_indexer_screen.dart';
import 'prowlarr_history_screen.dart';
import 'prowlarr_indexers_screen.dart';
import 'prowlarr_search_screen.dart';

/// Prowlarr module home — release search is the main body (search field on
/// top like other modules); Indexers and History sit in the bottom bar
/// around the central "+" FAB, which adds an indexer.
class ProwlarrHomeScreen extends StatefulWidget {
  const ProwlarrHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<ProwlarrHomeScreen> createState() => _ProwlarrHomeScreenState();
}

class _ProwlarrHomeScreenState extends State<ProwlarrHomeScreen> {
  void _openSubScreen(String title, Widget body) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Prowlarr',
      tabs: const [],
      tabViews: [ProwlarrSearchScreen(instance: widget.instance)],
      floatingActionButton: FloatingActionButton(
        backgroundColor: ServiceType.prowlarr.brandColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Indexer',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProwlarrAddIndexerScreen(instance: widget.instance),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      bottomLeadingActions: [
        BottomBarButton(
          icon: Icons.dns_outlined,
          label: 'Indexers',
          onTap: () => _openSubScreen(
            'Indexers',
            ProwlarrIndexersScreen(instance: widget.instance),
          ),
        ),
      ],
      bottomTrailingActions: [
        BottomBarButton(
          icon: Icons.history,
          label: 'History',
          onTap: () => _openSubScreen(
            'History',
            ProwlarrHistoryScreen(instance: widget.instance),
          ),
        ),
      ],
    );
  }
}
