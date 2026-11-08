import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

/// Poster-grid column count on phones (2 or 3), persisted in the DB.
/// Tablets (>=600dp) render one extra column on top of this.
final gridColumnsProvider = NotifierProvider<_GridColumnsNotifier, int>(
  _GridColumnsNotifier.new,
);

class _GridColumnsNotifier extends Notifier<int> {
  static const _key = 'grid_columns';

  @override
  int build() {
    _loadFromDb();
    return 3;
  }

  Future<void> _loadFromDb() async {
    final stored = await ref.read(dbProvider).getSetting(_key);
    final value = int.tryParse(stored ?? '');
    if ((value == 2 || value == 3) && value != state) {
      state = value!;
    }
  }

  Future<void> setColumns(int value) async {
    state = value;
    await ref.read(dbProvider).setSetting(_key, '$value');
  }
}

/// Persisted customizations; screens observe the same settings immediately.
final customizationProvider =
    NotifierProvider<CustomizationNotifier, Map<String, dynamic>>(
      CustomizationNotifier.new,
    );

class CustomizationNotifier extends Notifier<Map<String, dynamic>> {
  static const defaults = <String, dynamic>{
    'defaultView': 'grid',
    'modulesView': 'grid',
    'showNowPlaying': true,
    'showDownloads': true,
    'showUpcoming': true,
    'showRequests': true,
    'weekStartsMonday': true,
    'use24HourTime': true,
    'artworkBackgrounds': true,
    'tautulliRefreshSeconds': 10,
    'historyPageSize': 100,
  };
  final _edited = <String>{};
  @override
  Map<String, dynamic> build() {
    _load();
    return {...defaults};
  }

  Future<void> _load() async {
    final raw = await ref.read(dbProvider).getSetting('customization');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final saved = <String, dynamic>{};
      for (final e in defaults.entries) {
        final value = decoded[e.key];
        if ((e.value is bool && value is bool) ||
            (e.value is String && (value == 'grid' || value == 'list')) ||
            (e.key == 'tautulliRefreshSeconds' &&
                [10, 20, 30].contains(value)) ||
            (e.key == 'historyPageSize' && [50, 100, 200].contains(value))) {
          saved[e.key] = value;
        }
      }
      state = {
        ...defaults,
        ...saved,
        for (final key in _edited) key: state[key],
      };
    } on FormatException {
      /* Ignore an invalid saved preference. */
    }
  }

  Future<void> set(String key, dynamic value) async {
    _edited.add(key);
    state = {...state, key: value};
    await ref.read(dbProvider).setSetting('customization', jsonEncode(state));
  }
}
