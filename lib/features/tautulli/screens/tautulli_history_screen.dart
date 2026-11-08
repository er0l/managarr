import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/module_app_bar.dart';
import '../../settings/providers/ui_prefs_provider.dart';
import '../api/models/tautulli_history.dart';
import '../providers/tautulli_providers.dart';
import '../widgets/tautulli_artwork_card.dart';
import 'tautulli_media_detail_screen.dart';
import 'tautulli_user_detail_screen.dart';

String historyDate(DateTime? date, bool use24Hour) => date == null
    ? 'Unknown date'
    : DateFormat(
        use24Hour ? 'MMM d, y · HH:mm' : 'MMM d, y · h:mm a',
      ).format(date);

class TautulliHistoryScreen extends ConsumerWidget {
  const TautulliHistoryScreen({super.key, required this.instance});
  final Instance instance;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(tautulliHistoryProvider(instance));
    final use24 = ref.watch(customizationProvider)['use24HourTime'] == true;
    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Retry history'),
          onPressed: () => ref.invalidate(tautulliHistoryProvider(instance)),
        ),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async =>
            ref.refresh(tautulliHistoryProvider(instance).future),
        child: data.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No watch history')),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: data.items.length,
                itemBuilder: (context, index) {
                  final item = data.items[index];
                  return TautulliArtworkCard(
                    instance: instance,
                    poster: item.poster,
                    art: item.background,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TautulliHistoryDetailScreen(
                          instance: instance,
                          item: item,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (item.subtitle.isNotEmpty)
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          historyDate(item.startedAt ?? item.stoppedAt, use24),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${item.friendlyName ?? item.user ?? 'Unknown user'} · ${item.percentComplete}% watched',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class TautulliHistoryDetailScreen extends ConsumerWidget {
  const TautulliHistoryDetailScreen({
    super.key,
    required this.instance,
    required this.item,
  });
  final Instance instance;
  final TautulliHistoryItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final use24 = ref.watch(customizationProvider)['use24HourTime'] == true;
    final key = (instance: instance, rowId: item.rowId);
    final stream = item.rowId > 0
        ? ref.watch(tautulliStreamDataProvider(key))
        : null;
    return Scaffold(
      appBar: ModuleAppBar(
        title: const Text('History details'),
        actions: [
          if (item.userId > 0)
            IconButton(
              tooltip: 'User details',
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TautulliUserDetailScreen(
                    instance: instance,
                    userId: item.userId,
                    displayName: item.friendlyName ?? item.user ?? 'User',
                  ),
                ),
              ),
            ),
          if (item.ratingKey.isNotEmpty)
            IconButton(
              tooltip: 'Media details',
              icon: const Icon(Icons.info_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TautulliMediaDetailScreen(
                    instance: instance,
                    ratingKey: item.ratingKey,
                    title: item.displayTitle,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          TautulliArtworkCard(
            instance: instance,
            poster: item.poster,
            art: item.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(item.subtitle),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: item.percentComplete / 100),
                const SizedBox(height: 4),
                Text('${item.percentComplete}% watched'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TautulliInfoRows(
                  values: {
                    'User': item.friendlyName ?? item.user ?? 'Unknown',
                    'Started': historyDate(item.startedAt, use24),
                    'Stopped': historyDate(item.stoppedAt, use24),
                    'Watch time':
                        '${item.duration ~/ 3600}h ${(item.duration % 3600) ~/ 60}m',
                    'Player': item.player ?? '',
                    'Platform': item.platform ?? '',
                    'IP address': item.ipAddress ?? '',
                    'Stream': item.transcodeDecision ?? '',
                    'Quality': item.quality ?? '',
                  },
                ),
                if (stream != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Stream information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  stream.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => TextButton(
                      onPressed: () =>
                          ref.invalidate(tautulliStreamDataProvider(key)),
                      child: const Text(
                        'Stream information unavailable · Retry',
                      ),
                    ),
                    data: (data) => TautulliInfoRows(
                      values: {
                        'Video': [
                          data['video_codec'],
                          data['video_full_resolution'] ??
                              data['video_resolution'],
                        ].whereType<String>().join(' · '),
                        'Audio': [
                          data['audio_codec'],
                          data['audio_language'],
                        ].whereType<String>().join(' · '),
                        'Container': data['container']?.toString() ?? '',
                        'Subtitle': data['subtitle_codec']?.toString() ?? '',
                        'Bitrate': data['bitrate'] != null
                            ? '${data['bitrate']} kbps'
                            : '',
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
