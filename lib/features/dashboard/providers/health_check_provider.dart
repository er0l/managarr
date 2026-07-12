import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/rtorrent/api/rtorrent_api.dart';
import '../models/health_result.dart';

/// Checks connectivity for a single [Instance].
///
/// Results are kept alive for a short window so opening the drawer or
/// switching tabs reuses the dashboard's cached checks instead of
/// re-firing a request per instance. Pull-to-refresh invalidates.
final healthCheckProvider = FutureProvider.autoDispose
    .family<HealthResult, Instance>((ref, instance) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 2), link.close);

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

    if (type == ServiceType.tautulli) {
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
