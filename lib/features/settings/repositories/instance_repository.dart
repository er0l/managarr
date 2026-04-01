import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

class InstanceRepository {
  const InstanceRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  Stream<List<Instance>> watchAll() =>
      (_db.select(_db.instances)..orderBy([(t) => OrderingTerm.asc(t.serviceType)])).watch();

  Future<Instance?> getById(int id) =>
      (_db.select(_db.instances)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  Future<int> insert(InstancesCompanion companion) =>
      _db.into(_db.instances).insert(companion);

  Future<bool> update(InstancesCompanion companion) =>
      _db.update(_db.instances).replace(companion);

  Future<int> delete(int id) =>
      (_db.delete(_db.instances)..where((t) => t.id.equals(id))).go();
}

final instanceRepositoryProvider = Provider<InstanceRepository>((ref) {
  return InstanceRepository(ref.watch(dbProvider));
});
