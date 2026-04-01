import 'package:drift/drift.dart';

/// Drift table definition for service instances.
class Instances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Stored as the enum name string (e.g. 'radarr', 'sonarr').
  TextColumn get serviceType => text()();

  TextColumn get baseUrl => text()();
  TextColumn get apiKey => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
