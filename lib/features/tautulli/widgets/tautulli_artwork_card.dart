import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../settings/providers/ui_prefs_provider.dart';
import '../providers/tautulli_providers.dart';

class TautulliArtworkCard extends ConsumerWidget {
  const TautulliArtworkCard({
    super.key,
    required this.instance,
    required this.child,
    this.poster,
    this.art,
    this.onTap,
  });
  final Instance instance;
  final Widget child;
  final String? poster, art;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final api = ref.watch(tautulliApiProvider(instance));
    final backgrounds =
        ref.watch(customizationProvider)['artworkBackgrounds'] == true;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (backgrounds && art?.isNotEmpty == true)
              Positioned.fill(
                child: Opacity(
                  opacity: .22,
                  child: Image.network(
                    api.artUrl(art!),
                    headers: api.imageHeaders,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.surface.withAlpha(100),
                      colors.surface.withAlpha(225),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      width: 64,
                      height: 96,
                      child: poster?.isNotEmpty == true
                          ? Image.network(
                              api.thumbUrl(poster!),
                              headers: api.imageHeaders,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.movie_outlined),
                            )
                          : const Icon(Icons.movie_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TautulliInfoRows extends StatelessWidget {
  const TautulliInfoRows({super.key, required this.values});
  final Map<String, String> values;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final e in values.entries)
        if (e.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 112,
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Text(e.value)),
              ],
            ),
          ),
    ],
  );
}
