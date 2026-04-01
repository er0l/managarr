import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../repositories/instance_repository.dart';

/// Stream of all instances, ordered by service type.
final instancesProvider = StreamProvider<List<Instance>>((ref) {
  return ref.watch(instanceRepositoryProvider).watchAll();
});

/// Instances grouped by [ServiceType].
final instancesByServiceProvider =
    Provider<Map<ServiceType, List<Instance>>>((ref) {
  final instances = ref.watch(instancesProvider).valueOrNull ?? [];
  final map = <ServiceType, List<Instance>>{};
  for (final instance in instances) {
    final type = ServiceType.values.byName(instance.serviceType);
    map.putIfAbsent(type, () => []).add(instance);
  }
  return map;
});
