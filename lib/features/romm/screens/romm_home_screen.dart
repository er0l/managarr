import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../api/models/romm_platform.dart';
import '../providers/romm_providers.dart';
import 'romm_platform_screen.dart';

class RommHomeScreen extends StatefulWidget {
  const RommHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<RommHomeScreen> createState() => _RommHomeScreenState();
}

class _RommHomeScreenState extends State<RommHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Platforms'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'ROMM',
      tabs: _tabs,
      tabController: _tabController,
      tabViews: [
        _PlatformsTab(instance: widget.instance),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Platforms tab
// ---------------------------------------------------------------------------

class _PlatformsTab extends ConsumerWidget {
  const _PlatformsTab({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformsAsync = ref.watch(rommPlatformsProvider(instance));

    return platformsAsync.when(
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
              onPressed: () => ref.invalidate(rommPlatformsProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (platforms) {
        if (platforms.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videogame_asset_outlined,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No platforms found'),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(rommPlatformsProvider(instance)),
          color: AppColors.tealPrimary,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: platforms.length,
            itemBuilder: (ctx, i) => _PlatformCard(
              platform: platforms[i],
              instance: instance,
            ),
          ),
        );
      },
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({required this.platform, required this.instance});

  final RommPlatform platform;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RommPlatformScreen(instance: instance, platform: platform),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo or icon
              SizedBox(
                height: 36,
                child: platform.urlLogo != null && platform.urlLogo!.isNotEmpty
                    ? Image.network(
                        platform.urlLogo!,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.videogame_asset_outlined,
                          size: 32,
                          color: AppColors.tealPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.videogame_asset_outlined,
                        size: 32,
                        color: AppColors.tealPrimary,
                      ),
              ),
              const Spacer(),
              Text(
                platform.displayName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${platform.romCount} ROMs',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
