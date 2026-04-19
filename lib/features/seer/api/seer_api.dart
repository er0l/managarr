import 'package:dio/dio.dart';

import '../../../core/database/app_database.dart';
import 'models/media_detail.dart';
import 'models/media_request.dart';
import 'models/search_result.dart';
import 'models/seer_issue.dart';
import 'models/seer_user.dart';

class SeerApi {
  SeerApi(this._dio);

  final Dio _dio;

  static SeerApi fromInstance(Instance instance) {
    String host = instance.baseUrl.trim();
    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: '$host/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': instance.apiKey,
        },
        responseType: ResponseType.json,
      ),
    );
    return SeerApi(dio);
  }

  Future<Map<String, dynamic>> getStatus() async {
    final res = await _dio.get('/status');
    return res.data as Map<String, dynamic>;
  }

  Future<List<SeerMediaRequest>> getRequests({int page = 1}) async {
    final res = await _dio.get('/request', queryParameters: {'take': 20, 'skip': (page - 1) * 20});
    final results = (res.data['results'] as List? ?? []);
    final requests = results
        .map((j) => SeerMediaRequest.fromJson(j as Map<String, dynamic>))
        .toList();

    // Enrich requests that have placeholder titles
    await Future.wait(requests.map((req) async {
      if (req.title.startsWith('Movie ') ||
          req.title.startsWith('TV Show ') ||
          req.title.startsWith('Request ') ||
          req.overview.isEmpty) {
        try {
          if (req.mediaType == 'movie') {
            final detail = await getMovie(req.tmdbId);
            if (detail != null) {
              req.title = detail.title;
              req.overview = detail.overview;
              if (req.posterPath.isEmpty && detail.posterPath.isNotEmpty) {
                req.posterPath = detail.posterPath;
              }
            }
          } else {
            final detail = await getTv(req.tmdbId);
            if (detail != null) {
              req.title = detail.title;
              req.overview = detail.overview;
              if (req.posterPath.isEmpty && detail.posterPath.isNotEmpty) {
                req.posterPath = detail.posterPath;
              }
            }
          }
        } catch (_) {}
      }
    }));

    return requests;
  }

  Future<List<SeerSearchResult>> search(String query, {int page = 1}) async {
    // Use Uri.encodeComponent (%20 for spaces) instead of Dio's default
    // queryParameters encoding which uses + — some servers/proxies reject +.
    final res = await _dio.get(
      '/search?query=${Uri.encodeComponent(query)}&page=$page',
    );
    return (res.data['results'] as List? ?? [])
        .map((j) => SeerSearchResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<bool> requestMedia({
    required int tmdbId,
    required String mediaType,
    bool is4k = false,
  }) async {
    await _dio.post('/request', data: {
      'mediaId': tmdbId,
      'mediaType': mediaType,
      'is4k': is4k,
    });
    return true;
  }

  Future<SeerMediaDetail?> getMovie(int id) async {
    try {
      final res = await _dio.get('/movie/$id');
      if (res.statusCode == 200) {
        return SeerMediaDetail.fromJson(res.data as Map<String, dynamic>, 'movie');
      }
    } catch (_) {}
    return null;
  }

  Future<SeerMediaDetail?> getTv(int id) async {
    try {
      final res = await _dio.get('/tv/$id');
      if (res.statusCode == 200) {
        return SeerMediaDetail.fromJson(res.data as Map<String, dynamic>, 'tv');
      }
    } catch (_) {}
    return null;
  }

  Future<List<SeerIssue>> getIssues({
    int page = 1,
    int pageSize = 25,
    int? status, // 1=open, 2=resolved; null=all
  }) async {
    final res = await _dio.get('/issue', queryParameters: {
      'take': pageSize,
      'skip': (page - 1) * pageSize,
      'status': ?status,
    });
    final results = res.data['results'] as List? ?? [];
    return results
        .map((j) => SeerIssue.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<bool> updateIssueStatus(int issueId, int status) async {
    // status: 1=open, 2=resolved
    await _dio.post('/issue/$issueId/${status == 2 ? 'resolved' : 'open'}');
    return true;
  }

  Future<List<SeerUser>> getUsers({int pageSize = 100}) async {
    final res = await _dio.get('/user', queryParameters: {
      'take': pageSize,
      'skip': 0,
      'sort': 'created',
    });
    final results = res.data['results'] as List? ?? [];
    return results
        .map((j) => SeerUser.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<SeerMediaRequest>> getUserRequests(int userId,
      {int pageSize = 50}) async {
    final res = await _dio.get('/user/$userId/requests',
        queryParameters: {'take': pageSize, 'skip': 0});
    final results = res.data['results'] as List? ?? [];
    return results
        .map((j) => SeerMediaRequest.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveRequest(int id) async {
    await _dio.post('/request/$id/approve');
  }

  Future<void> declineRequest(int id) async {
    await _dio.post('/request/$id/decline');
  }

  Future<List<SeerSearchResult>> getDiscoverMovies({
    int page = 1,
    String sortBy = 'popularity.desc',
  }) async {
    final res = await _dio.get('/discover/movies', queryParameters: {
      'page': page,
      'sortBy': sortBy,
    });
    return (res.data['results'] as List? ?? [])
        .map((j) => SeerSearchResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<SeerSearchResult>> getDiscoverTv({
    int page = 1,
    String sortBy = 'popularity.desc',
  }) async {
    final res = await _dio.get('/discover/tv', queryParameters: {
      'page': page,
      'sortBy': sortBy,
    });
    return (res.data['results'] as List? ?? [])
        .map((j) => SeerSearchResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}

