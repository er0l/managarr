import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/rtorrent/api/rtorrent_api.dart';
import '../models/health_result.dart';

/// Checks connectivity for a single [Instance].
/// Auto-disposed so it re-runs whenever the instance changes.
final healthCheckProvider = FutureProvider.autoDispose
    .family<HealthResult, Instance>((ref, instance) async {
  final type = ServiceType.values.byName(instance.serviceType);
  final stopwatch = Stopwatch()..start();

  try {
    if (type.usesXmlRpc) {
      final api = RTorrentApi.fromInstance(instance);
      await api.testConnection();
      stopwatch.stop();
      return HealthResult(
        online: true,
        checkedAt: DateTime.now(),
        responseMs: stopwatch.elapsedMilliseconds,
      );
    }

    final dio = ref.read(dioProvider(instance));
    final Response response;

    if (type.usesSabnzbdAuth) {
      response = await dio.get(
        type.healthPath,
        queryParameters: {
          'mode': 'version',
          'output': 'json',
          'apikey': instance.apiKey,
        },
        options: Options(headers: {}), // strip X-Api-Key added by interceptor
      );
    } else if (type == ServiceType.tautulli) {
      response = await dio.get(
        type.healthPath,
        queryParameters: {'apikey': instance.apiKey},
      );
    } else {
      response = await dio.get(type.healthPath);
    }

    stopwatch.stop();
    final data = response.data;

    return HealthResult(
      online: true,
      checkedAt: DateTime.now(),
      version: data is Map ? data['version'] as String? : null,
      instanceName: data is Map ? data['instanceName'] as String? : null,
      responseMs: stopwatch.elapsedMilliseconds,
    );
  } on DioException {
    stopwatch.stop();
    return HealthResult.offline(DateTime.now());
  } catch (_) {
    stopwatch.stop();
    return HealthResult.offline(DateTime.now());
  }
});

/// All enabled instances with their health status, grouped for the dashboard.
final dashboardHealthProvider = Provider.autoDispose<
    Map<Instance, AsyncValue<HealthResult>>>((ref) {
  final instances = ref.watch(instancesStreamProvider).valueOrNull ?? [];
  return {
    for (final i in instances.where((i) => i.enabled))
      i: ref.watch(healthCheckProvider(i)),
  };
});

// Re-export so dashboard_screen only needs one import.
final instancesStreamProvider = StreamProvider.autoDispose<List<Instance>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.instances)
        ..orderBy([(t) => OrderingTerm.asc(t.serviceType)]))
      .watch();
});
