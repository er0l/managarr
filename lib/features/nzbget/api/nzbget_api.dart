import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';
import 'models/nzbget_history.dart';
import 'models/nzbget_log.dart';
import 'models/nzbget_queue.dart';
import 'models/nzbget_status.dart';

class NzbgetApi {
  final Dio _dio;

  NzbgetApi(this._dio);

  static NzbgetApi fromInstance(Instance instance) {
    String host = instance.baseUrl.trim();
    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }

    final username = instance.apiKey.contains(':')
        ? instance.apiKey.split(':').first
        : '';
    final password = instance.apiKey.contains(':')
        ? instance.apiKey.split(':').last
        : instance.apiKey;
    final credential = '$username:$password';
    final Map<String, dynamic> headers = {};
    if (credential != ':') {
      final encoded = base64.encode(utf8.encode(credential));
      headers['Authorization'] = 'Basic $encoded';
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: host,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        headers: headers,
      ),
    );
    return NzbgetApi(dio);
  }

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>('/jsonrpc', data: body);
    return response.data ?? {};
  }

  Future<NzbgetStatus> getStatus() async {
    final response = await _call({
      "jsonrpc": "2.0",
      "method": "status",
      "params": [],
      "id": 1,
    });
    return NzbgetStatus.fromJson(response['result'] ?? {});
  }

  Future<NzbgetQueue> getQueue() async {
    final response = await _call({
      "jsonrpc": "2.0",
      "method": "listgroups",
      "params": [],
      "id": 1,
    });
    final result = response['result'] as List? ?? [];
    return NzbgetQueue.fromJson(result);
  }

  Future<NzbgetHistory> getHistory({bool hidden = false}) async {
    final response = await _call({
      "jsonrpc": "2.0",
      "method": "history",
      "params": [hidden],
      "id": 1,
    });
    final result = response['result'] as List? ?? [];
    return NzbgetHistory.fromJson(result);
  }

  Future<NzbgetLogs> getLogs({int amount = 50}) async {
    final response = await _call({
      "jsonrpc": "2.0",
      "method": "log",
      "params": [0, amount],
      "id": 1,
    });
    final result = response['result'] as List? ?? [];
    return NzbgetLogs.fromJson(result);
  }

  Future<void> pauseDownload() async {
    await _call({
      "jsonrpc": "2.0",
      "method": "pausedownload",
      "params": [],
      "id": 1,
    });
  }

  Future<void> resumeDownload() async {
    await _call({
      "jsonrpc": "2.0",
      "method": "resumedownload",
      "params": [],
      "id": 1,
    });
  }

  Future<void> deleteJob(int id) async {
    await _call({
      "jsonrpc": "2.0",
      "method": "editqueue",
      "params": ["GroupFinalDelete", "", [id]],
      "id": 1,
    });
  }

  Future<void> deleteHistory(int id) async {
    await _call({
      "jsonrpc": "2.0",
      "method": "editqueue",
      "params": ["HistoryFinalDelete", "", [id]],
      "id": 1,
    });
  }
}
