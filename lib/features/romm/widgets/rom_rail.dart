import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../api/models/romm_rom.dart';
import '../providers/romm_providers.dart';
import '../screens/romm_rom_detail_screen.dart';

/// Horizontal poster rail ("Continue Playing", "Recently Added", …).
/// Collapses entirely when the source resolves empty or errors.
class RomRail extends ConsumerWidget {
  const RomRail({
    super.key,
    required this.title,
    required this.instance,
    required this.romsAsync,
  });

  final String title;
  final Instance instance;
  final AsyncValue<List<RommRom>> romsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roms = romsAsync.valueOrNull;

    if (roms != null && roms.isEmpty) return const SizedBox.shrink();
    if (romsAsync.hasError) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal,
            Spacing.s12,
            Spacing.pageHorizontal,
            Spacing.s8,
          ),
          child: Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 176,
          child: roms == null
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.pageHorizontal),
                  itemCount: 4,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: Spacing.s12),
                  itemBuilder: (_, _) => const ShimmerBox(
                      width: 96, height: 176, borderRadius: 10),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.pageHorizontal),
                  itemCount: roms.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: Spacing.s12),
                  itemBuilder: (context, index) =>
                      _RailCard(instance: instance, rom: roms[index]),
                ),
        ),
      ],
    );
  }
}

class _RailCard extends ConsumerWidget {
  const _RailCard({required this.instance, required this.rom});

  final Instance instance;
  final RommRom rom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final api = ref.watch(rommApiProvider(instance));
    final coverUrl = api.coverUrl(rom);

    return SizedBox(
      width: 96,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RommRomDetailScreen(
              instance: instance,
              romId: rom.id,
              romName: rom.name,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 96,
                height: 128,
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        // Only RomM-hosted covers need auth — never leak the
                        // header to external CDNs (IGDB).
                        headers: coverUrl.startsWith(api.baseUrl)
                            ? {'Authorization': api.authHeader}
                            : null,
                        errorBuilder: (_, _, _) => const _CoverFallback(),
                      )
                    : const _CoverFallback(),
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              rom.name,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              rom.platformDisplayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.videogame_asset_outlined,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }
}
