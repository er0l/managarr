import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/module_app_bar.dart';
import '../api/models/tautulli_history.dart';
import '../providers/tautulli_providers.dart';
import '../widgets/tautulli_artwork_card.dart';

class TautulliMediaDetailScreen extends ConsumerWidget {
  const TautulliMediaDetailScreen({
    super.key,
    required this.instance,
    required this.ratingKey,
    required this.title,
  });
  final Instance instance;
  final String ratingKey, title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (instance: instance, ratingKey: ratingKey);
    final metadata = ref.watch(tautulliMetadataProvider(key));
    return Scaffold(
      appBar: ModuleAppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: metadata.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Media details are unavailable'),
              TextButton.icon(
                onPressed: () => ref.invalidate(tautulliMetadataProvider(key)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          String value(String name) => data[name]?.toString() ?? '';
          String names(String name) => data[name] is List
              ? (data[name] as List)
                    .map((e) => e is Map ? e['tag'] ?? e['name'] ?? '' : e)
                    .join(', ')
              : value(name);
          final type = value('media_type');
          final name = value('title');
          final show = value('grandparent_title');
          final duration = tautulliInt(data['duration']) ~/ 60000;
          final season = tautulliInt(data['parent_media_index']);
          final episode = tautulliInt(data['media_index']);
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              TautulliArtworkCard(
                instance: instance,
                poster: data['thumb']?.toString(),
                art: data['art']?.toString(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (show.isNotEmpty)
                      Text(
                        show,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    Text(
                      name.isEmpty ? title : name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (type == 'episode')
                          'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}',
                        if (value('year').isNotEmpty) value('year'),
                        if (duration > 0) '$duration min',
                        value('content_rating'),
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (value('summary').isNotEmpty) ...[
                      Text(value('summary')),
                      const SizedBox(height: 20),
                    ],
                    TautulliInfoRows(
                      values: {
                        'Type': type,
                        'Studio': value('studio'),
                        'Genres': names('genres'),
                        'Directors': names('directors'),
                        'Writers': names('writers'),
                        'Cast': names('actors'),
                        'Originally aired': value('originally_available_at'),
                        'Rating': value('rating'),
                        'Library': value('library_name'),
                      },
                    ),
                    if (type == 'episode' &&
                        value('grandparent_rating_key').isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.tv_outlined),
                        label: const Text('Series details'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TautulliMediaDetailScreen(
                              instance: instance,
                              ratingKey: value('grandparent_rating_key'),
                              title: show,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
