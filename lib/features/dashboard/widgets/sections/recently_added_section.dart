import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../romm/providers/romm_providers.dart';
import '../../../romm/screens/romm_rom_detail_screen.dart';
import '../../../settings/providers/ui_prefs_provider.dart';
import '../../../tautulli/providers/tautulli_providers.dart';
import '../../../tautulli/screens/tautulli_media_detail_screen.dart';
import '../../providers/recently_added_provider.dart';

class RecentlyAddedSection extends ConsumerStatefulWidget {
  const RecentlyAddedSection({super.key});

  @override
  ConsumerState<RecentlyAddedSection> createState() =>
      _RecentlyAddedSectionState();
}

class _RecentlyAddedSectionState extends ConsumerState<RecentlyAddedSection> {
  RecentKind? _kind;

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(dashboardRecentSourcesProvider);
    final prefs = ref.watch(customizationProvider);
    final kinds = RecentKind.values
        .where((k) => prefs[k.preference] == true)
        .toList();
    final selected = kinds.contains(_kind) ? _kind : null;
    final visible = sources
        .where((s) => selected == null || s.kind == selected)
        .toList();
    final items = newestAdditions(visible);
    final loading = visible.any((s) => s.items.isLoading);
    final failed = visible.where((s) => s.items.hasError);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recently Added'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selected == null,
                onSelected: (_) => setState(() => _kind = null),
              ),
              for (final kind in kinds)
                ChoiceChip(
                  label: Text(kind.label),
                  selected: selected == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final source in failed)
          ListTile(
            title: Text(
              '${source.kind.label} unavailable · ${source.instance.name}',
            ),
            trailing: TextButton(
              onPressed: () {
                if (source.kind == RecentKind.roms) {
                  ref.invalidate(rommRecentlyAddedProvider(source.instance));
                } else {
                  ref.invalidate(
                    dashboardPlexRecentProvider((
                      instance: source.instance,
                      kind: source.kind,
                    )),
                  );
                }
              },
              child: const Text('Retry'),
            ),
          ),
        if (items.isNotEmpty)
          SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) => _RecentCard(item: items[index]),
            ),
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: 110, height: 165, borderRadius: 12),
          )
        else if (failed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              sources.isEmpty
                  ? 'Recently Added uses Tautulli for movies, TV and music, and ROMM for games. Enable a source in Settings.'
                  : 'Nothing recently added',
            ),
          ),
      ],
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.item});
  final RecentAddition item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    String? url;
    Map<String, String>? headers;
    if (item.rom != null) {
      final api = ref.watch(rommApiProvider(item.instance));
      url = api.coverUrl(item.rom!);
      if (url != null &&
          Uri.parse(url).origin == Uri.parse(api.baseUrl).origin) {
        headers = {'Authorization': api.authHeader};
      }
    } else {
      final api = ref.watch(tautulliApiProvider(item.instance));
      final poster = item.kind == RecentKind.episodes
          ? item.media!.grandparentThumb ?? item.media!.thumb
          : item.media!.thumb;
      if (poster?.isNotEmpty == true) url = api.thumbUrl(poster!);
      headers = api.imageHeaders;
    }
    final icon = switch (item.kind) {
      RecentKind.movies => Icons.movie_outlined,
      RecentKind.episodes => Icons.tv_outlined,
      RecentKind.music => Icons.album_outlined,
      RecentKind.roms => Icons.sports_esports_outlined,
    };
    final fallback = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
    return SizedBox(
      width: 110,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => item.rom != null
                ? RommRomDetailScreen(
                    instance: item.instance,
                    romId: item.rom!.id,
                    romName: item.title,
                  )
                : TautulliMediaDetailScreen(
                    instance: item.instance,
                    ratingKey: item.media!.ratingKey,
                    title: item.title,
                  ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 110,
                height: 165,
                child: url == null
                    ? fallback
                    : Image.network(
                        url,
                        headers: headers,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
            Text(
              [
                item.kind.label,
                if (item.addedAt != null)
                  DateFormat.MMMd().format(item.addedAt!.toLocal()),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
