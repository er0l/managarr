import 'package:dio/dio.dart';

import 'models/calendar.dart';
import 'models/cutoff_record.dart';
import 'models/episode.dart';
import 'models/history.dart';
import 'models/quality_profile.dart';
import 'models/queue.dart';
import 'models/release.dart';
import 'models/root_folder.dart';
import 'models/series.dart';
import 'models/system_status.dart';
import 'models/tag.dart';

class SonarrApi {
  SonarrApi(this._dio);

  final Dio _dio;

  Future<List<SonarrSeries>> getSeries() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/series');
    return (response.data ?? [])
        .map((e) => SonarrSeries.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SonarrCalendar>> getCalendar(DateTime start, DateTime end) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/calendar',
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'includeSeries': true,
        'includeEpisodeFile': true,
      },
    );
    return (response.data ?? [])
        .map((e) => SonarrCalendar.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SonarrQueue> getQueue() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v3/queue');
    return SonarrQueue.fromJson(response.data!);
  }

  Future<SonarrHistory> getHistory() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v3/history');
    return SonarrHistory.fromJson(response.data!);
  }

  Future<SonarrSystemStatus> getSystemStatus() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/v3/system/status');
    return SonarrSystemStatus.fromJson(response.data!);
  }

  Future<SonarrSeries> getSeriesById(int id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/v3/series/$id');
    return SonarrSeries.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> getSeriesRaw(int id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/v3/series/$id');
    return Map<String, dynamic>.from(response.data!);
  }

  Future<SonarrSeries> toggleMonitorSeries(int id, bool monitored) async {
    final getResp =
        await _dio.get<Map<String, dynamic>>('/api/v3/series/$id');
    final json = Map<String, dynamic>.from(getResp.data!);
    json['monitored'] = monitored;
    final putResp = await _dio.put<Map<String, dynamic>>(
      '/api/v3/series/$id',
      data: json,
    );
    return SonarrSeries.fromJson(putResp.data!);
  }

  Future<SonarrSeries> updateSeries(Map<String, dynamic> data) async {
    final id = data['id'] as int;
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v3/series/$id',
      data: data,
      queryParameters: {'moveFiles': false},
    );
    return SonarrSeries.fromJson(response.data!);
  }

  Future<void> deleteSeries(int id, {bool deleteFiles = false}) async {
    await _dio.delete(
      '/api/v3/series/$id',
      queryParameters: {'deleteFiles': deleteFiles},
    );
  }

  Future<void> refreshSeries(int id) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {'name': 'RefreshSeries', 'seriesId': id},
    );
  }

  Future<void> searchSeries(int id) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {'name': 'SeriesSearch', 'seriesId': id},
    );
  }

  Future<void> searchSeason(int seriesId, int seasonNumber) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {
        'name': 'SeasonSearch',
        'seriesId': seriesId,
        'seasonNumber': seasonNumber,
      },
    );
  }

  Future<void> searchEpisode(int episodeId) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {'name': 'EpisodeSearch', 'episodeIds': [episodeId]},
    );
  }

  Future<void> sendCommand(String name) async {
    await _dio.post<void>(
      '/api/v3/command',
      data: {'name': name},
    );
  }

  Future<List<SonarrSeries>> lookupSeries(String term) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/series/lookup',
      queryParameters: {'term': term},
    );
    return (response.data ?? [])
        .map((e) => SonarrSeries.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SonarrSeries> addSeries(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v3/series',
      data: data,
    );
    return SonarrSeries.fromJson(response.data!);
  }

  Future<List<SonarrQualityProfile>> getQualityProfiles() async {
    final response =
        await _dio.get<List<dynamic>>('/api/v3/qualityprofile');
    return (response.data ?? [])
        .map((e) =>
            SonarrQualityProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SonarrRootFolder>> getRootFolders() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/rootfolder');
    return (response.data ?? [])
        .map((e) => SonarrRootFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SonarrTag>> getTags() async {
    final response = await _dio.get<List<dynamic>>('/api/v3/tag');
    return (response.data ?? [])
        .map((e) => SonarrTag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SonarrTag> createTag(String label) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v3/tag',
      data: {'label': label},
    );
    return SonarrTag.fromJson(response.data!);
  }

  Future<void> deleteTag(int id) async {
    await _dio.delete('/api/v3/tag/$id');
  }

  Future<List<SonarrEpisode>> getEpisodes(int seriesId, int seasonNumber) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/episode',
      queryParameters: {
        'seriesId': seriesId,
        'seasonNumber': seasonNumber,
      },
    );
    return (response.data ?? [])
        .map((e) => SonarrEpisode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SonarrRelease>> getReleases({
    int? seriesId,
    int? seasonNumber,
    int? episodeId,
  }) async {
    final params = <String, dynamic>{};
    if (seriesId != null) params['seriesId'] = seriesId;
    if (seasonNumber != null) params['seasonNumber'] = seasonNumber;
    if (episodeId != null) params['episodeId'] = episodeId;

    final response = await _dio.get<List<dynamic>>(
      '/api/v3/release',
      queryParameters: params,
    );
    return (response.data ?? [])
        .map((e) => SonarrRelease.fromJson(e as Map<String, dynamic>))
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

  Future<List<SonarrCutoffRecord>> getCutoffUnmet(
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
        .map((e) => SonarrCutoffRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
