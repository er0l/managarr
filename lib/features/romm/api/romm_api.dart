import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import 'models/romm_available_filters.dart';
import 'models/romm_collection.dart';
import 'models/romm_platform.dart';
import 'models/romm_rom.dart';
import 'models/romm_search_filters.dart';
import 'models/romm_stats.dart';

class RommApi {
  RommApi._(this._dio, this._baseUrl, this._authHeader);

  final Dio _dio;
  final String _baseUrl;
  final String _authHeader;

  factory RommApi.fromInstance(Instance instance) {
    final encoded = base64.encode(utf8.encode(instance.apiKey));
    final authHeader = 'Basic $encoded';
    final dio = Dio(
      BaseOptions(
        baseUrl: '${instance.baseUrl}/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Authorization': authHeader},
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }

    return RommApi._(dio, instance.baseUrl, authHeader);
  }

  // ---------------------------------------------------------------------------
  // Platforms
  // ---------------------------------------------------------------------------

  Future<List<RommPlatform>> getPlatforms() async {
    final res = await _dio.get<List>('/platforms');
    return (res.data ?? [])
        .map((j) => RommPlatform.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Collections
  // ---------------------------------------------------------------------------

  Future<List<RommCollection>> getCollections() async {
    final res = await _dio.get<List>('/collections');
    return (res.data ?? [])
        .map((j) => RommCollection.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // ROMs
  // ---------------------------------------------------------------------------

  Future<List<RommRom>> getRoms(
    int platformId, {
    String? searchTerm,
    int limit = 50,
    int offset = 0,
    String? orderBy,
    String? orderDir,
  }) async {
    final params = <String, dynamic>{
      'platform_ids': platformId,
      'limit': limit,
      'offset': offset,
    };
    if (searchTerm != null && searchTerm.isNotEmpty) {
      params['search_term'] = searchTerm;
    }
    if (orderBy != null) params['order_by'] = orderBy;
    if (orderDir != null) params['order_dir'] = orderDir;
    final res = await _dio.get<Map<String, dynamic>>(
      '/roms',
      queryParameters: params,
    );
    final items = res.data?['items'] as List? ?? [];
    return items
        .map((j) => RommRom.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<RommRom>> getCollectionRoms(
    int collectionId, {
    String? searchTerm,
    int limit = 50,
    int offset = 0,
    String? orderBy,
    String? orderDir,
  }) async {
    final params = <String, dynamic>{
      'collection_id': collectionId,
      'limit': limit,
      'offset': offset,
    };
    if (searchTerm != null && searchTerm.isNotEmpty) {
      params['search_term'] = searchTerm;
    }
    if (orderBy != null) params['order_by'] = orderBy;
    if (orderDir != null) params['order_dir'] = orderDir;
    final res = await _dio.get<Map<String, dynamic>>(
      '/roms',
      queryParameters: params,
    );
    final items = res.data?['items'] as List? ?? [];
    return items
        .map((j) => RommRom.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<RommRom>> searchRoms(
    String? searchTerm,
    RommSearchFilters filters, {
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (searchTerm != null && searchTerm.isNotEmpty) {
      params['search_term'] = searchTerm;
    }
    if (filters.platformIds.isNotEmpty) {
      params['platform_ids'] = filters.platformIds.join(',');
    }
    if (filters.genres.isNotEmpty) {
      params['genres'] = filters.genres.join(',');
    }
    if (filters.franchises.isNotEmpty) {
      params['franchises'] = filters.franchises.join(',');
    }
    if (filters.companies.isNotEmpty) {
      params['companies'] = filters.companies.join(',');
    }
    if (filters.ageRatings.isNotEmpty) {
      params['age_ratings'] = filters.ageRatings.join(',');
    }
    if (filters.regions.isNotEmpty) {
      params['regions'] = filters.regions.join(',');
    }
    if (filters.languages.isNotEmpty) {
      params['languages'] = filters.languages.join(',');
    }
    final res = await _dio.get<Map<String, dynamic>>(
      '/roms',
      queryParameters: params,
    );
    final items = res.data?['items'] as List? ?? [];
    return items
        .map((j) => RommRom.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<RommRom> getRomDetail(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/roms/$id');
    return RommRom.fromJson(res.data!);
  }

  // ---------------------------------------------------------------------------
  // Filters (available options for search)
  // ---------------------------------------------------------------------------

  Future<RommAvailableFilters> getAvailableFilters() async {
    final res = await _dio.get<Map<String, dynamic>>('/roms/filters');
    return RommAvailableFilters.fromJson(res.data ?? {});
  }

  // ---------------------------------------------------------------------------
  // ROM CRUD
  // ---------------------------------------------------------------------------

  Future<void> deleteRom(int id) async {
    await _dio.delete('/roms/$id');
  }

  Future<RommRom> updateRom(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch<Map<String, dynamic>>('/roms/$id', data: data);
    return RommRom.fromJson(res.data!);
  }

  Future<void> toggleFavourite(int id, bool isFavourite) async {
    await _dio.patch<void>('/roms/$id', data: {'is_favourite': isFavourite});
  }

  // ---------------------------------------------------------------------------
  // Stats & Health
  // ---------------------------------------------------------------------------

  Future<RommStats> getStats() async {
    final res = await _dio.get<Map<String, dynamic>>('/stats');
    return RommStats.fromJson(res.data ?? {});
  }

  Future<bool> heartbeat() async {
    try {
      await _dio.get<dynamic>('/heartbeat');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> scanLibrary() async {
    await _dio.post<void>('/tasks/scan_library');
  }

  // ---------------------------------------------------------------------------
  // Collection CRUD
  // ---------------------------------------------------------------------------

  Future<RommCollection> createCollection(String name,
      {String? description}) async {
    final res = await _dio.post<Map<String, dynamic>>('/collections', data: {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    return RommCollection.fromJson(res.data!);
  }

  Future<RommCollection> updateCollection(int id, String name,
      {String? description}) async {
    final data = <String, dynamic>{'name': name};
    if (description != null) data['description'] = description;
    final res = await _dio.patch<Map<String, dynamic>>(
      '/collections/$id',
      data: data,
    );
    return RommCollection.fromJson(res.data!);
  }

  Future<void> deleteCollection(int id) async {
    await _dio.delete('/collections/$id');
  }

  Future<void> addRomsToCollection(int collectionId, List<int> romIds) async {
    await _dio
        .post<void>('/collections/$collectionId/roms', data: {'roms': romIds});
  }

  Future<void> removeRomFromCollection(int collectionId, int romId) async {
    await _dio.delete('/collections/$collectionId/roms/$romId');
  }

  // ---------------------------------------------------------------------------
  // URLs
  // ---------------------------------------------------------------------------

  /// Direct download URL for a ROM file.
  String downloadUrl(int romId, String fileName) =>
      '$_baseUrl/api/roms/$romId/content/${Uri.encodeComponent(fileName)}';

  /// Base URL (without /api suffix) for asset requests.
  String get baseUrl => _baseUrl;

  /// Auth header to include with image/download requests.
  String get authHeader => _authHeader;

  /// Cover image URL — prefers external IGDB URL, falls back to ROMM-hosted.
  String? coverUrl(RommRom rom) {
    if (rom.urlCover != null && rom.urlCover!.isNotEmpty) return rom.urlCover;
    if (rom.pathCoverLarge != null && rom.pathCoverLarge!.isNotEmpty) {
      return '$_baseUrl/api/raw/assets/${rom.pathCoverLarge}';
    }
    if (rom.pathCoverSmall != null && rom.pathCoverSmall!.isNotEmpty) {
      return '$_baseUrl/api/raw/assets/${rom.pathCoverSmall}';
    }
    return null;
  }
}
