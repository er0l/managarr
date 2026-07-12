import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/instances_table.dart';
import 'tables/app_settings_table.dart';

export 'tables/instances_table.dart';
export 'tables/app_settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Instances, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'managarr'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(appSettings);
          }
          if (from < 3) {
            // Rename serviceType value 'jellyseerr' → 'seer'
            await customStatement(
              "UPDATE instances SET service_type = 'seer' WHERE service_type = 'jellyseerr'",
            );
          }
          if (from < 4) {
            await m.addColumn(instances, instances.localUrl);
          }
          if (from < 5) {
            await m.addColumn(instances, instances.proxyUsername);
            await m.addColumn(instances, instances.proxyPassword);
          }
          if (from < 6) {
            // SABnzbd and NZBGet modules were removed in v1.6.1; leftover
            // rows would crash ServiceType.values.byName.
            await customStatement(
              "DELETE FROM instances WHERE service_type IN ('sabnzbd', 'nzbget')",
            );
          }
        },
      );

  // ---------------------------------------------------------------------------
  // AppSettings helpers
  // ---------------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }
}

final dbProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('dbProvider must be overridden in main()'),
);
