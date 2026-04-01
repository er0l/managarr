import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';

import 'models/tautulli_activity.dart';
import 'models/tautulli_graph_data.dart';
import 'models/tautulli_history.dart';
import 'models/tautulli_home_stats.dart';
import 'models/tautulli_library.dart';
import 'models/tautulli_log_entry.dart';
import 'models/tautulli_media_item.dart';
import 'models/tautulli_user.dart';
import 'models/tautulli_user_detail.dart';

class TautulliApi {
  final Dio _dio;
  final String _baseUrl;
  final String _apiKey;

  TautulliApi(this._dio, this._baseUrl, this._apiKey);

  static TautulliApi fromInstance(Instance instance) {
    String host = instance.baseUrl.trim();
    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    final baseUrl = host.contains('/api/v2') ? host : '$host/api/v2';
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        queryParameters: {'apikey': instance.apiKey},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
      ),
    );
    return TautulliApi(dio, host, instance.apiKey);
  }

  Future<Map<String, dynamic>> _get(
      String cmd, [Map<String, dynamic>? extra]) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '',
      queryParameters: {
        'cmd': cmd,
        if (extra != null) ...extra,
      },
    );
    return response.data ?? {};
  }

  // ─── Existing endpoints ────────────────────────────────────────────────

  Future<TautulliActivity> getActivity() async {
    final response = await _get('get_activity');
    final data = response['response']?['data'] ?? {};
    return TautulliActivity.fromJson(data as Map<String, dynamic>);
  }

  Future<TautulliHistory> getHistory({int length = 50, int? userId}) async {
    final response = await _get('get_history', {
      'length': length,
      'user_id': ?userId,
    });
    final data = response['response']?['data'] ?? {};
    return TautulliHistory.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TautulliLibrary>> getLibraries() async {
    final response = await _get('get_libraries');
    final data = response['response']?['data'] as List? ?? [];
    return data
        .map((l) => TautulliLibrary.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  Future<List<TautulliUser>> getUsers() async {
    // get_users_table includes last_seen; get_users does not.
    final response = await _get('get_users_table', {'length': 1000});
    final data =
        response['response']?['data']?['data'] as List? ?? [];
    return data
        .map((u) => TautulliUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  // ─── New endpoints ─────────────────────────────────────────────────────

  Future<List<TautulliMediaItem>> getRecentlyAdded({
    int count = 50,
    String? mediaType,
  }) async {
    final response = await _get('get_recently_added', {
      'count': count,
      'media_type': ?mediaType,
    });
    final data =
        response['response']?['data']?['recently_added'] as List? ?? [];
    return data
        .map((m) => TautulliMediaItem.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<TautulliHomeStats> getHomeStats() async {
    final response = await _get('get_home_stats');
    final data = response['response']?['data'] as List? ?? [];
    return TautulliHomeStats.fromJson(data);
  }

  Future<TautulliUserDetail> getUserDetail(int userId) async {
    final userResp = await _get('get_user', {'user_id': userId});
    final userData =
        userResp['response']?['data'] as Map<String, dynamic>? ?? {};

    final statsResp =
        await _get('get_user_watch_time_stats', {'user_id': userId});
    final statsData = statsResp['response']?['data'] as List? ?? [];

    return TautulliUserDetail.fromJson(
      userJson: userData,
      watchTimeJson: statsData,
    );
  }

  Future<List<TautulliMediaItem>> getLibraryMediaInfo(
    int sectionId, {
    int start = 0,
    int length = 50,
  }) async {
    final response = await _get('get_library_media_info', {
      'section_id': sectionId,
      'start': start,
      'length': length,
    });
    final data = response['response']?['data']?['data'] as List? ?? [];
    return data
        .map((m) => TautulliMediaItem.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<TautulliMediaItem>>> librarySearch(
      String query) async {
    final raw = await _get('search', {'query': query, 'limit': 20});

    // Navigate response envelope
    final env = raw['response'];
    if (env is! Map) return {};
    final data = env['data'];
    if (data is! Map) return {};

    // Tautulli uses 'results_list' (newer) or 'results' (older) as the key.
    final resultsRaw = data['results_list'] ?? data['results'];

    final grouped = <String, List<TautulliMediaItem>>{};

    if (resultsRaw is Map) {
      // Older format: Map<type, {title, results_count, results:[…]}>
      for (final entry in resultsRaw.entries) {
        final type = entry.key as String;
        final section = entry.value;
        List? rows;
        if (section is Map) {
          rows = (section['results_list'] ?? section['results']) as List?;
        } else if (section is List) {
          rows = section;
        }
        if (rows != null && rows.isNotEmpty) {
          grouped[type] = rows
              .whereType<Map<String, dynamic>>()
              .map(TautulliMediaItem.fromJson)
              .toList();
        }
      }
    } else if (resultsRaw is List) {
      // Newer flat-list format – group by media_type field
      for (final item in resultsRaw.whereType<Map<String, dynamic>>()) {
        final type = (item['media_type'] as String?) ?? 'unknown';
        grouped.putIfAbsent(type, () => []).add(TautulliMediaItem.fromJson(item));
      }
    }

    return grouped;
  }

  Future<List<TautulliLogEntry>> getLogs({int count = 100}) async {
    final response = await _get('get_logs', {'start': 0, 'end': count});
    final data = response['response']?['data'] as List? ?? [];
    return data
        .map((l) => TautulliLogEntry.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  // ─── Graph endpoints ───────────────────────────────────────────────────

  Future<TautulliGraphData> _getGraph(String cmd,
      {int timeRange = 30, String yAxis = 'plays'}) async {
    final response = await _get(cmd, {
      'time_range': timeRange,
      'y_axis': yAxis,
    });
    final data =
        response['response']?['data'] as Map<String, dynamic>? ?? {};
    return TautulliGraphData.fromJson(data);
  }

  Future<TautulliGraphData> getGraphPlaysByDate({int timeRange = 30}) =>
      _getGraph('get_plays_by_date', timeRange: timeRange);

  Future<TautulliGraphData> getGraphPlaysByMonth({int timeRange = 12}) =>
      _getGraph('get_plays_per_month', timeRange: timeRange);

  Future<TautulliGraphData> getGraphPlaysByDayOfWeek({int timeRange = 30}) =>
      _getGraph('get_plays_by_dayofweek', timeRange: timeRange);

  Future<TautulliGraphData> getGraphPlaysByTopPlatforms(
          {int timeRange = 30}) =>
      _getGraph('get_plays_by_top_10_platforms', timeRange: timeRange);

  Future<TautulliGraphData> getGraphPlaysByTopUsers({int timeRange = 30}) =>
      _getGraph('get_plays_by_top_10_users', timeRange: timeRange);

  Future<TautulliGraphData> getGraphStreamTypeByDate({int timeRange = 30}) =>
      _getGraph('get_plays_by_stream_type', timeRange: timeRange);

  Future<TautulliGraphData> getGraphStreamTypeByTopPlatforms(
          {int timeRange = 30}) =>
      _getGraph('get_stream_type_by_top_10_platforms', timeRange: timeRange);

  Future<TautulliGraphData> getGraphStreamTypeByTopUsers(
          {int timeRange = 30}) =>
      _getGraph('get_stream_type_by_top_10_users', timeRange: timeRange);

  /// Terminates a Plex stream by session key.
  Future<void> terminateSession(String sessionKey, {String message = 'Stream stopped by admin'}) async {
    await _get('terminate_session', {'session_key': sessionKey, 'message': message});
  }

  /// Builds a pms_image_proxy URL for a Plex poster/thumb.
  String thumbUrl(String thumb) {
    final base =
        _baseUrl.contains('/api/v2') ? _baseUrl : '$_baseUrl/api/v2';
    return '$base?cmd=pms_image_proxy&img=${Uri.encodeComponent(thumb)}&apikey=$_apiKey&width=150&height=225';
  }
}
