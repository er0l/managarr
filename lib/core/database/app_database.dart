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
  int get schemaVersion => 3;

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
