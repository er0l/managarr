import 'package:dio/dio.dart';

import '../../../core/database/app_database.dart';
import 'models/history_item.dart';
import 'models/queue_item.dart';

class SabnzbdApi {
  SabnzbdApi._(this._dio, this._apiKey, this._basePath);

  final Dio _dio;
  final String _apiKey;
  final String _basePath;

  factory SabnzbdApi.fromInstance(Instance instance) {
    String host = instance.baseUrl.trim();
    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
      ),
    );
    return SabnzbdApi._(dio, instance.apiKey, '$host/api');
  }

  Future<Map<String, dynamic>> _get(
    String mode, {
    Map<String, dynamic>? extra,
  }) async {
    final params = <String, dynamic>{
      'mode': mode,
      'output': 'json',
      'apikey': _apiKey,
      ...?extra,
    };
    final res = await _dio.get(_basePath, queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVersion() => _get('version');

  Future<SabnzbdQueue> getQueue() async {
    final data = await _get('queue');
    return SabnzbdQueue.fromJson(data);
  }

  Future<List<SabnzbdHistoryItem>> getHistory({int limit = 50}) async {
    final data = await _get('history', extra: {'limit': limit});
    final history = data['history'] as Map<String, dynamic>? ?? {};
    final slots = (history['slots'] as List? ?? [])
        .map((j) => SabnzbdHistoryItem.fromJson(j as Map<String, dynamic>))
        .toList();
    return slots;
  }

  Future<bool> pauseQueue() async {
    await _get('pause');
    return true;
  }

  Future<bool> resumeQueue() async {
    await _get('resume');
    return true;
  }

  Future<bool> pauseItem(String nzoId) async {
    await _get('queue', extra: {'name': 'pause', 'value': nzoId});
    return true;
  }

  Future<bool> resumeItem(String nzoId) async {
    await _get('queue', extra: {'name': 'resume', 'value': nzoId});
    return true;
  }

  Future<bool> deleteItem(String nzoId, {bool deleteFiles = false}) async {
    await _get('queue', extra: {
      'name': 'delete',
      'value': nzoId,
      'del_files': deleteFiles ? '1' : '0',
    });
    return true;
  }

  Future<bool> deleteHistoryItem(String nzoId) async {
    await _get('history', extra: {'name': 'delete', 'value': nzoId});
    return true;
  }

  Future<bool> setSpeed(int kbps) async {
    await _get('config', extra: {'name': 'speedlimit', 'value': kbps});
    return true;
  }
}
