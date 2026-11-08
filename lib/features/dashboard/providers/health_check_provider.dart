import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/rtorrent/providers/rtorrent_providers.dart';
import '../models/health_result.dart';

/// Checks connectivity for a single [Instance].
///
/// Results are kept alive for a short window so opening the drawer or
/// switching tabs reuses the dashboard's cached checks instead of
/// re-firing a request per instance. Pull-to-refresh invalidates.
final healthCheckProvider = FutureProvider.autoDispose.family<HealthResult, Instance>((
  ref,
  instance,
) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 2), link.close);
  ref.onDispose(timer.cancel);

  final type = ServiceType.values.byName(instance.serviceType);
  final stopwatch = Stopwatch()..start();

  try {
    if (type.usesXmlRpc) {
      final api = ref.watch(rtorrentApiProvider(instance));
      await api.testConnection();
      stopwatch.stop();
      String? version;
      try {
        version = _version(
          await api.getVersion().timeout(const Duration(seconds: 5)),
        );
      } catch (_) {
        // Restricted XML-RPC commands must not turn a reachable client offline.
      }
      return HealthResult(
        online: true,
        checkedAt: DateTime.now(),
        responseMs: stopwatch.elapsedMilliseconds,
        version: version,
      );
    }

    final dio = ref.watch(dioProvider(instance));
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
    if (type == ServiceType.tautulli &&
        (data is! Map ||
            data['response'] is! Map ||
            data['response']['result'] != 'success')) {
      return HealthResult.offline(DateTime.now());
    }
    String? version = data is Map ? _version(data['version']) : null;
    if (version == null) {
      try {
        version = await _serviceVersion(
          dio,
          type,
          instance.apiKey,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Version metadata is optional; the authenticated health check succeeded.
      }
    }

    return HealthResult(
      online: true,
      checkedAt: DateTime.now(),
      version: version,
      instanceName: data is Map && data['instanceName'] is String
          ? data['instanceName'] as String
          : null,
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

/// Normalize optional metadata without assuming every server returns a string.
String? _version(dynamic value) {
  if (value is! String) return null;
  final version = value.trim().replaceFirst(RegExp(r'^[vV](?=\d)'), '');
  return version.isEmpty ? null : version;
}

Future<String?> _serviceVersion(
  Dio dio,
  ServiceType type,
  String apiKey,
) async {
  switch (type) {
    case ServiceType.seer:
      final response = await dio.get('/api/v1/status');
      final data = response.data;
      return data is Map ? _version(data['version']) : null;
    case ServiceType.romm:
      final response = await dio.get('/api/heartbeat');
      final data = response.data;
      if (data is! Map) return null;
      final system = data['SYSTEM'];
      return _version(system is Map ? system['VERSION'] : data['version']);
    case ServiceType.tautulli:
      final response = await dio.get(
        '/api/v2',
        queryParameters: {'cmd': 'get_tautulli_info', 'apikey': apiKey},
      );
      final data = response.data;
      if (data is! Map || data['response'] is! Map) return null;
      final envelope = data['response'] as Map;
      final info = envelope['data'];
      return envelope['result'] == 'success' && info is Map
          ? _version(info['tautulli_version'])
          : null;
    default:
      return null;
  }
}
