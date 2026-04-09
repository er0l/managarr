import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import 'models/romm_platform.dart';
import 'models/romm_rom.dart';

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
  // ROMs
  // ---------------------------------------------------------------------------

  Future<List<RommRom>> getRoms(
    int platformId, {
    String? searchTerm,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'platform_ids': platformId,
      'limit': limit,
      'offset': offset,
    };
    if (searchTerm != null && searchTerm.isNotEmpty) {
      params['search_term'] = searchTerm;
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
  // URLs
  // ---------------------------------------------------------------------------

  /// Direct download URL for a ROM file.
  String downloadUrl(int romId, String fileName) =>
      '$_baseUrl/api/roms/$romId/content/${Uri.encodeComponent(fileName)}';

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
