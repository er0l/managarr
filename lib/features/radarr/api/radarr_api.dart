import 'package:dio/dio.dart';

import 'models/history.dart';
import 'models/movie.dart';
import 'models/movie_file.dart';
import 'models/quality_profile.dart';
import 'models/queue.dart';
import 'models/release.dart';
import 'models/root_folder.dart';
import 'models/system_status.dart';
import 'models/tag.dart';

class RadarrApi {
  RadarrApi(this._dio);

  final Dio _dio;

  Future<List<RadarrMovie>> getMovies() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/movie');
    return (response.data ?? [])
        .map((e) => RadarrMovie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RadarrMovie>> getCalendar(DateTime start, DateTime end) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/calendar',
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'unmonitored': 'true',
      },
    );
    return (response.data ?? [])
        .map((e) => RadarrMovie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RadarrQueue> getQueue() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v3/queue');
    return RadarrQueue.fromJson(response.data!);
  }

  Future<RadarrHistory> getHistory({int page = 1, int pageSize = 100}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v3/history',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return RadarrHistory.fromJson(response.data!);
  }

  Future<List<RadarrQualityProfile>> getQualityProfiles() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/qualityprofile');
    return (response.data ?? [])
        .map((e) => RadarrQualityProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RadarrSystemStatus> getSystemStatus() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/v3/system/status');
    return RadarrSystemStatus.fromJson(response.data!);
  }

  Future<RadarrMovie> toggleMonitorMovie(int id, bool monitored) async {
    final getResp = await _dio.get<Map<String, dynamic>>('/api/v3/movie/$id');
    final json = Map<String, dynamic>.from(getResp.data!);
    json['monitored'] = monitored;
    final putResp = await _dio.put<Map<String, dynamic>>(
      '/api/v3/movie/$id',
      data: json,
    );
    return RadarrMovie.fromJson(putResp.data!);
  }

  Future<void> deleteMovie(int id, {bool deleteFiles = false}) async {
    await _dio.delete(
      '/api/v3/movie/$id',
      queryParameters: {'deleteFiles': deleteFiles},
    );
  }

  Future<void> refreshMovie(int id) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {'name': 'RefreshMovie', 'movieIds': [id]},
    );
  }

  Future<void> searchMovie(int id) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {'name': 'MoviesSearch', 'movieIds': [id]},
    );
  }

  Future<void> sendCommand(String name) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {'name': name},
    );
  }

  Future<List<RadarrRootFolder>> getRootFolders() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/rootfolder');
    return (response.data ?? [])
        .map((e) => RadarrRootFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RadarrMovie>> lookupMovie(String term) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/movie/lookup',
      queryParameters: {'term': term},
    );
    return (response.data ?? [])
        .map((e) => RadarrMovie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RadarrMovie> addMovie(Map<String, dynamic> movieData) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v3/movie',
      data: movieData,
    );
    return RadarrMovie.fromJson(response.data!);
  }

  Future<RadarrMovie> getMovieById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v3/movie/$id');
    return RadarrMovie.fromJson(response.data!);
  }

  /// Fetches the full movie JSON (all fields) for editing.
  Future<Map<String, dynamic>> getMovieRaw(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v3/movie/$id');
    return response.data!;
  }

  /// Updates an existing movie. Sends the full movie JSON back.
  Future<RadarrMovie> updateMovie(Map<String, dynamic> movieData) async {
    final id = movieData['id'];
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v3/movie/$id',
      data: movieData,
    );
    return RadarrMovie.fromJson(response.data!);
  }

  // ── Movie Files ──────────────────────────────────────────────────────

  Future<List<RadarrMovieFile>> getMovieFiles(int movieId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/moviefile',
      queryParameters: {'movieId': movieId},
    );
    return (response.data ?? [])
        .map((e) => RadarrMovieFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteMovieFile(int id) async {
    await _dio.delete('/api/v3/moviefile/$id');
  }

  // ── Per-movie History ────────────────────────────────────────────────

  Future<RadarrHistory> getMovieHistory(int movieId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v3/history',
      queryParameters: {
        'movieId': movieId,
        'pageSize': 50,
      },
    );
    return RadarrHistory.fromJson(response.data!);
  }

  // ── Releases ─────────────────────────────────────────────────────────

  Future<List<RadarrRelease>> getReleases(int movieId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/release',
      queryParameters: {'movieId': movieId},
    );
    return (response.data ?? [])
        .map((e) => RadarrRelease.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> grabRelease(String guid, int indexerId) async {
    await _dio.post<void>(
      '/api/v3/release',
      data: {'guid': guid, 'indexerId': indexerId},
    );
  }

  // ── Health ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHealth() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/health');
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  // ── Disk Space ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDiskSpace() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/diskspace');
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  // ── Tags ─────────────────────────────────────────────────────────────

  Future<List<RadarrTag>> getTags() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/tag');
    return (response.data ?? [])
        .map((e) => RadarrTag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RadarrTag> createTag(String label) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v3/tag',
      data: {'label': label},
    );
    return RadarrTag.fromJson(response.data!);
  }

  Future<void> deleteTag(int id) async {
    await _dio.delete('/api/v3/tag/$id');
  }

  Future<List<Map<String, dynamic>>> getManualImport(String folder) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/manualimport',
      queryParameters: {
        'folder': folder,
        'filterExistingFiles': true,
      },
    );
    return (response.data ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> executeManualImport(
      List<Map<String, dynamic>> items) async {
    await _dio.post('/api/v3/manualimport', data: items);
  }

  Future<List<RadarrMovie>> getCutoffUnmet(
      {int page = 1, int pageSize = 100}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v3/wanted/cutoff',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'monitored': true,
      },
    );
    final records = response.data?['records'] as List? ?? [];
    return records
        .map((e) => RadarrMovie.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
