import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

/// One completed ROM download saved to the device.
class RommDownloadRecord {
  const RommDownloadRecord({
    required this.romName,
    required this.fileName,
    required this.sizeBytes,
    required this.savedAt,
    required this.instanceName,
    this.savedPath,
  });

  final String romName;
  final String fileName;
  final int sizeBytes;
  final DateTime savedAt;
  final String instanceName;
  final String? savedPath;

  Map<String, dynamic> toJson() => {
        'romName': romName,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        'savedAt': savedAt.toIso8601String(),
        'instanceName': instanceName,
        if (savedPath != null) 'savedPath': savedPath,
      };

  factory RommDownloadRecord.fromJson(Map<String, dynamic> json) =>
      RommDownloadRecord(
        romName: json['romName'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
        instanceName: json['instanceName'] as String? ?? '',
        savedPath: json['savedPath'] as String?,
      );
}

/// Download history persisted as JSON in the app settings table.
/// Newest first, capped so the settings row stays small.
abstract final class RommDownloadHistory {
  static const _key = 'romm_download_history';
  static const _maxEntries = 100;

  static Future<List<RommDownloadRecord>> load(AppDatabase db) async {
    final raw = await db.getSetting(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(RommDownloadRecord.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> add(AppDatabase db, RommDownloadRecord record) async {
    final current = await load(db);
    final updated = [record, ...current].take(_maxEntries).toList();
    await _save(db, updated);
  }

  static Future<void> removeAt(AppDatabase db, int index) async {
    final current = await load(db);
    if (index < 0 || index >= current.length) return;
    final updated = List<RommDownloadRecord>.from(current)..removeAt(index);
    await _save(db, updated);
  }

  static Future<void> clear(AppDatabase db) => _save(db, const []);

  static Future<void> _save(
      AppDatabase db, List<RommDownloadRecord> records) async {
    await db.setSetting(
        _key, jsonEncode([for (final r in records) r.toJson()]));
  }
}

final rommDownloadHistoryProvider =
    FutureProvider.autoDispose<List<RommDownloadRecord>>((ref) {
  final db = ref.watch(dbProvider);
  return RommDownloadHistory.load(db);
});
