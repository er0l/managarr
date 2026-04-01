import 'package:drift/drift.dart';

/// Simple key-value table for storing app-level settings.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
