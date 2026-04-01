import 'package:dio/dio.dart';

import '../../../core/database/app_database.dart';
import 'models/indexer.dart';
import 'models/prowlarr_history.dart';
import 'models/prowlarr_search_result.dart';

class ProwlarrApi {
  ProwlarrApi(this._dio);

  final Dio _dio;

  factory ProwlarrApi.fromInstance(Instance instance) {
    String host = instance.baseUrl.trim();
    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: '$host/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'X-Api-Key': instance.apiKey},
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
}
