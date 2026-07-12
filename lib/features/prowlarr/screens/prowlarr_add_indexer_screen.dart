import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/prowlarr_providers.dart';

/// Searchable list of Prowlarr indexer definitions. Tapping one adds it
/// with its schema defaults — works out of the box for public indexers;
/// private ones that need an API key report Prowlarr's validation error.
class ProwlarrAddIndexerScreen extends ConsumerStatefulWidget {
  const ProwlarrAddIndexerScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<ProwlarrAddIndexerScreen> createState() =>
      _ProwlarrAddIndexerScreenState();
}

class _ProwlarrAddIndexerScreenState
    extends ConsumerState<ProwlarrAddIndexerScreen> {
  final _controller = TextEditingController();
  String _filter = '';
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add(Map<String, dynamic> schema) async {
    final name = schema['name'] as String? ?? 'Indexer';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add indexer'),
        content: Text(
          'Add "$name" with default settings?\n\n'
          'Private indexers that require an API key must be configured '
          'in the Prowlarr web UI.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(prowlarrApiProvider(widget.instance));
      await api.addIndexer(schema);
      ref.invalidate(prowlarrIndexersProvider(widget.instance));
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Added "$name"'),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      var message = '$e';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is List && data.isNotEmpty && data.first is Map) {
          message = (data.first as Map)['errorMessage']?.toString() ?? message;
        } else if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Could not add "$name": $message'),
        backgroundColor: AppColors.statusOffline,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemasAsync =
        ref.watch(prowlarrIndexerSchemasProvider(widget.instance));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add Indexer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search indexers…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) =>
                  setState(() => _filter = v.trim().toLowerCase()),
            ),
          ),
          if (_adding) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: schemasAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.statusOffline),
                    const SizedBox(height: 12),
                    const Text('Failed to load indexer list'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(
                          prowlarrIndexerSchemasProvider(widget.instance)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (schemas) {
                final filtered = _filter.isEmpty
                    ? schemas
                    : schemas
                        .where((s) => (s['name'] as String? ?? '')
                            .toLowerCase()
                            .contains(_filter))
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No indexers match'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _SchemaTile(schema: filtered[index], onAdd: _add),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemaTile extends StatelessWidget {
  const _SchemaTile({required this.schema, required this.onAdd});

  final Map<String, dynamic> schema;
  final ValueChanged<Map<String, dynamic>> onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = schema['name'] as String? ?? 'Unknown';
    final protocol = schema['protocol'] as String? ?? '';
    final privacy = schema['privacy'] as String? ?? '';
    final description = schema['description'] as String? ?? '';

    return ListTile(
      dense: true,
      title: Text(name,
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          if (protocol.isNotEmpty) protocol,
          if (privacy.isNotEmpty) privacy,
          if (description.isNotEmpty) description,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(
        privacy == 'private' ? Icons.lock_outline : Icons.add_circle_outline,
        size: 20,
        color: privacy == 'private'
            ? theme.colorScheme.onSurfaceVariant
            : AppColors.tealPrimary,
      ),
      onTap: () => onAdd(schema),
    );
  }
}
