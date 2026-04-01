import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../repositories/instance_repository.dart';

abstract final class BackupRestoreService {
  // ── Backup ────────────────────────────────────────────────────────────────

  static Future<void> backup(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(instanceRepositoryProvider);
    try {
      final instances = await repo.getAll();
      final json = jsonEncode({
        'version': 1,
        'instances': instances
            .map((i) => {
                  'name': i.name,
                  'serviceType': i.serviceType,
                  'baseUrl': i.baseUrl,
                  'apiKey': i.apiKey,
                  'enabled': i.enabled,
                })
            .toList(),
      });
      final bytes = const Utf8Encoder().convert(json);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup',
        fileName: 'managarr_backup.json',
        bytes: bytes,
      );
      if (!context.mounted) return;
      if (path != null) _snack(context, 'Backup saved');
    } catch (e) {
      if (context.mounted) _snack(context, 'Backup failed: $e', error: true);
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  static Future<void> restore(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select backup file',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (context.mounted) _snack(context, 'Could not read file', error: true);
      return;
    }

    late Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      if (context.mounted) _snack(context, 'Invalid backup file', error: true);
      return;
    }

    final rawList = parsed['instances'];
    if (rawList is! List || rawList.isEmpty) {
      if (context.mounted) {
        _snack(context, 'No instances found in backup', error: true);
      }
      return;
    }

    if (!context.mounted) return;
    final mode = await _askRestoreMode(context, rawList.length);
    if (mode == null) return;

    final repo = ref.read(instanceRepositoryProvider);
    try {
      if (mode == _RestoreMode.replace) await repo.deleteAll();
      for (final raw in rawList) {
        final m = raw as Map<String, dynamic>;
        await repo.insert(InstancesCompanion(
          name: Value(m['name'] as String),
          serviceType: Value(m['serviceType'] as String),
          baseUrl: Value(m['baseUrl'] as String),
          apiKey: Value(m['apiKey'] as String),
          enabled: Value((m['enabled'] as bool?) ?? true),
        ));
      }
      if (context.mounted) {
        _snack(context,
            'Restored ${rawList.length} instance${rawList.length == 1 ? '' : 's'}');
      }
    } catch (e) {
      if (context.mounted) _snack(context, 'Restore failed: $e', error: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<_RestoreMode?> _askRestoreMode(
      BuildContext context, int count) {
    return showDialog<_RestoreMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore configuration'),
        content: Text(
          'Found $count instance${count == 1 ? '' : 's'} in the backup.\n\n'
          'Merge keeps your existing instances and adds the new ones.\n'
          'Replace removes all existing instances first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _RestoreMode.merge),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _RestoreMode.replace),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.statusOffline),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String message,
      {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.statusOffline : null,
    ));
  }
}

enum _RestoreMode { merge, replace }
