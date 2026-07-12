import 'package:dio/dio.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'models/indexer.dart';
import 'models/prowlarr_history.dart';
import 'models/prowlarr_search_result.dart';

class ProwlarrApi {
  ProwlarrApi(this._dio);

  final Dio _dio;

  factory ProwlarrApi.fromInstance(Instance instance) =>
      ProwlarrApi.fromHost(instance.baseUrl, instance.apiKey,
          proxyAuth: proxyAuthFor(instance, instance.baseUrl));

  factory ProwlarrApi.fromHost(String rawHost, String apiKey,
      {String? proxyAuth}) {
    final (:url, basicAuth: urlAuth) = extractUrlCredentials(rawHost.trim());
    final auth = proxyAuth ?? urlAuth;
    String host = url;
    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: '$host/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'X-Api-Key': apiKey,
          'Authorization': ?auth,
        },
        responseType: ResponseType.json,
      ),
    );
    return ProwlarrApi(dio);
  }

  Future<List<ProwlarrIndexer>> getIndexers() async {
    final res = await _dio.get('/indexer');
    return (res.data as List)
        .map((j) => ProwlarrIndexer.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProwlarrHealthItem>> getHealth() async {
    final res = await _dio.get('/health');
    return (res.data as List)
        .map((j) => ProwlarrHealthItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getSystemStatus() async {
    final res = await _dio.get('/system/status');
    return res.data as Map<String, dynamic>;
  }

  Future<bool> testIndexer(int id) async {
    await _dio.post('/indexer/test', data: {'id': id});
    return true;
  }

  Future<bool> deleteIndexer(int id) async {
    await _dio.delete('/indexer/$id');
    return true;
  }

  Future<List<ProwlarrHistoryItem>> getHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get('/history', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final records = (res.data as Map<String, dynamic>)['records'] as List? ?? [];
    return records
        .map((j) => ProwlarrHistoryItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProwlarrSearchResult>> search(
    String query, {
    List<int>? indexerIds,
  }) async {
    final params = <String, dynamic>{'query': query};
    if (indexerIds != null && indexerIds.isNotEmpty) {
      params['indexerIds'] = indexerIds;
    }
    final res = await _dio.get('/search', queryParameters: params);
    final data = res.data as List? ?? [];
    return data
        .map((j) => ProwlarrSearchResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<bool> grabRelease(String guid, int indexerId) async {
    await _dio.post('/search', data: {'guid': guid, 'indexerId': indexerId});
    return true;
  }

  /// All indexer definitions Prowlarr supports (GET /indexer/schema).
  Future<List<Map<String, dynamic>>> getIndexerSchemas() async {
    final res = await _dio.get('/indexer/schema');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  /// Adds an indexer from a schema definition. Public indexers usually work
  /// with their schema defaults; private ones may fail validation (API key
  /// required) — the error message is surfaced to the caller.
  Future<void> addIndexer(Map<String, dynamic> schema) async {
    final body = Map<String, dynamic>.from(schema)
      ..['enable'] = true
      ..['appProfileId'] = schema['appProfileId'] ?? 1;
    await _dio.post('/indexer', data: body);
  }
}
