import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

/// Poster-grid column count on phones (2 or 3), persisted in the DB.
/// Tablets (>=600dp) render one extra column on top of this.
final gridColumnsProvider =
    NotifierProvider<_GridColumnsNotifier, int>(_GridColumnsNotifier.new);

class _GridColumnsNotifier extends Notifier<int> {
  static const _key = 'grid_columns';

  @override
  int build() {
    _loadFromDb();
    return 2;
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
