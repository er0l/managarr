import 'package:dio/dio.dart';

import 'models/artist.dart';
import 'models/album.dart';
import 'models/history.dart';
import 'models/metadata_profile.dart';
import 'models/quality_profile.dart';
import 'models/queue.dart';
import 'models/release.dart';
import 'models/root_folder.dart';
import 'models/tag.dart';
import 'models/track.dart';

class LidarrApi {
  LidarrApi(this._dio);

  final Dio _dio;

  Future<List<LidarrArtist>> getArtists() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/artist');
    return (response.data ?? [])
        .map((e) => LidarrArtist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LidarrArtist>> lookupArtist(String term) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/artist/lookup',
      queryParameters: {'term': term},
    );
    return (response.data ?? [])
        .map((e) => LidarrArtist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LidarrArtist> addArtist(Map<String, dynamic> artistData) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/artist',
      data: artistData,
    );
    return LidarrArtist.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> getArtistRaw(int id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/v1/artist/$id');
    return Map<String, dynamic>.from(response.data!);
  }

  Future<LidarrArtist> updateArtist(Map<String, dynamic> data) async {
    final id = data['id'] as int;
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/artist/$id',
      data: data,
    );
    return LidarrArtist.fromJson(response.data!);
  }

  Future<void> deleteArtist(int id, {bool deleteFiles = false}) async {
    await _dio.delete(
      '/api/v1/artist/$id',
      queryParameters: {'deleteFiles': deleteFiles},
    );
  }

  Future<LidarrArtist> toggleMonitorArtist(int id, bool monitored) async {
    final raw = await getArtistRaw(id);
    raw['monitored'] = monitored;
    final putResp = await _dio.put<Map<String, dynamic>>(
      '/api/v1/artist/$id',
      data: raw,
    );
    return LidarrArtist.fromJson(putResp.data!);
  }

  Future<void> refreshArtist(int id) async {
    await _dio.post<void>(
      '/api/v1/command',
      data: {'name': 'RefreshArtist', 'artistId': id},
    );
  }

  Future<void> searchArtist(int id) async {
    await _dio.post<void>(
      '/api/v1/command',
      data: {'name': 'ArtistSearch', 'artistId': id},
    );
  }

  Future<void> sendCommand(String name) async {
    await _dio.post<void>(
      '/api/v1/command',
      data: {'name': name},
    );
  }

  Future<List<LidarrAlbum>> getAlbums(int artistId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/album',
      queryParameters: {'artistId': artistId},
    );
    return (response.data ?? [])
        .map((e) => LidarrAlbum.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LidarrTrack>> getTracks(int albumId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/track',
      queryParameters: {'albumId': albumId},
    );
    return (response.data ?? [])
        .map((e) => LidarrTrack.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LidarrQualityProfile>> getQualityProfiles() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/qualityprofile');
    return (response.data ?? [])
        .map((e) => LidarrQualityProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LidarrMetadataProfile>> getMetadataProfiles() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/metadataprofile');
    return (response.data ?? [])
        .map(
            (e) => LidarrMetadataProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LidarrRootFolder>> getRootFolders() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/rootfolder');
    return (response.data ?? [])
        .map((e) => LidarrRootFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LidarrTag>> getTags() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/tag');
    return (response.data ?? [])
        .map((e) => LidarrTag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LidarrTag> createTag(String label) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/tag',
      data: {'label': label},
    );
    return LidarrTag.fromJson(response.data!);
  }

  Future<LidarrQueue> getQueue() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/queue');
    return LidarrQueue.fromJson(response.data!);
  }

  Future<LidarrHistory> getHistory({int page = 1, int pageSize = 100}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/history',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return LidarrHistory.fromJson(response.data!);
  }

  Future<List<LidarrRelease>> getAlbumReleases(int albumId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/release',
      queryParameters: {'albumId': albumId},
    );
    return (response.data ?? [])
        .map((e) => LidarrRelease.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> grabRelease(String guid, int indexerId) async {
    await _dio.post<void>(
      '/api/v1/release',
      data: {'guid': guid, 'indexerId': indexerId},
    );
  }

  Future<List<LidarrAlbum>> getWantedMissing({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/wanted/missing',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    final records =
        (response.data?['records'] as List<dynamic>?) ?? [];
    return records
        .map((e) => LidarrAlbum.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
