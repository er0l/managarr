import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';

final drawerOrderProvider =
    NotifierProvider<DrawerOrderNotifier, List<ServiceType>>(
      DrawerOrderNotifier.new,
    );

class DrawerOrderNotifier extends Notifier<List<ServiceType>> {
  bool _edited = false;

  @override
  List<ServiceType> build() {
    _load();
    return [...ServiceType.values];
  }

  Future<void> _load() async {
    final raw = await ref.read(dbProvider).getSetting('drawer_order');
    if (raw == null || _edited) return;
    try {
      final saved = jsonDecode(raw);
      if (saved is! List) return;
      final names = saved.whereType<String>().toSet();
      state = [
        for (final name in names)
          for (final type in ServiceType.values)
            if (type.name == name) type,
        for (final type in ServiceType.values)
          if (!names.contains(type.name)) type,
      ];
    } on FormatException {
      // Keep the default order if the saved setting is invalid.
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final order = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    await _save(order);
  }

  Future<void> reset() => _save([...ServiceType.values]);

  Future<void> _save(List<ServiceType> order) async {
    _edited = true;
    state = order;
    await ref
        .read(dbProvider)
        .setSetting(
          'drawer_order',
          jsonEncode(order.map((type) => type.name).toList()),
        );
  }
}
