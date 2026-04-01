import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/prowlarr_search_result.dart';
import '../providers/prowlarr_providers.dart';

class ProwlarrSearchScreen extends ConsumerStatefulWidget {
  const ProwlarrSearchScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<ProwlarrSearchScreen> createState() =>
      _ProwlarrSearchScreenState();
}

class _ProwlarrSearchScreenState extends ConsumerState<ProwlarrSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    setState(() => _query = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = _query.isEmpty
        ? null
        : ref.watch(prowlarrSearchProvider(
            (instance: widget.instance, query: _query)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SearchBar(
            controller: _controller,
            hintText: 'Search all indexers...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                ),
            ],
            onSubmitted: _submit,
          ),
        ),
        Expanded(
          child: _buildResults(context, resultsAsync),
        ),
      ],
    );
  }

  Widget _buildResults(
    BuildContext context,
    AsyncValue<List<ProwlarrSearchResult>>? resultsAsync,
  ) {
    if (resultsAsync == null) {
      return const Center(
        child: Text(
          'Enter a search query above',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (results) {
        if (results.isEmpty) {
          return const Center(child: Text('No results found'));
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = results[index];
            return _SearchResultTile(
              result: result,
              onGrab: () => _confirmGrab(context, result),
            );
          },
        );
      },
    );
  }

  void _confirmGrab(BuildContext context, ProwlarrSearchResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grab Release'),
        content: Text(
          'Download "${result.title}" from ${result.indexerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(prowlarrApiProvider(widget.instance));
              final messenger = ScaffoldMessenger.of(context);
              try {
                await api.grabRelease(result.guid, result.indexerId);
                messenger.showSnackBar(const SnackBar(
                  content: Text('Release grabbed'),
                  backgroundColor: AppColors.statusOnline,
                ));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Grab failed: $e'),
                  backgroundColor: AppColors.statusOffline,
                ));
              }
            },
            child: const Text('Grab'),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onGrab});

  final ProwlarrSearchResult result;
  final VoidCallback onGrab;

  @override
  Widget build(BuildContext context) {
    final isTorrent = result.protocol == 'torrent';
    final protocolColor =
        isTorrent ? AppColors.blueAccent : AppColors.orangeAccent;

    return ListTile(
      title: Text(
        result.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            _Chip(
              label: isTorrent ? 'Torrent' : 'Usenet',
              color: protocolColor,
            ),
            const SizedBox(width: 6),
            Text(
              result.indexerName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              result.sizeFormatted,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (isTorrent && result.seeders != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.upload_outlined,
                  size: 12, color: AppColors.statusOnline),
              Text(
                '${result.seeders}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.statusOnline,
                    ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              result.ageFormatted,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.download_outlined, color: AppColors.tealPrimary),
        onPressed: onGrab,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
