import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/models/service_type.dart';

/// Extracts `user:pass` credentials embedded in a URL
/// (e.g. `https://user:pass@example.com`).
/// Returns the cleaned URL (without credentials) and a ready-made
/// `Authorization: Basic …` header value, or null if none present.
({String url, String? basicAuth}) extractUrlCredentials(String raw) {
  if (!raw.contains('@')) return (url: raw, basicAuth: null);
  try {
    final uri = Uri.parse(raw);
    if (uri.userInfo.isNotEmpty) {
      final auth =
          'Basic ${base64.encode(utf8.encode(Uri.decodeComponent(uri.userInfo)))}';
      final clean = uri.replace(userInfo: '').toString();
      return (url: clean, basicAuth: auth);
    }
  } catch (_) {}
  return (url: raw, basicAuth: null);
}

/// Typed API error wrapping a [DioException].
class ApiError implements Exception {
  const ApiError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiError($statusCode): $message';
}

/// Interceptor that injects the service API key as an HTTP header.
class _ApiKeyInterceptor extends Interceptor {
  _ApiKeyInterceptor(this.apiKey);

  final String apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Api-Key'] = apiKey;
    handler.next(options);
  }
}

/// Interceptor that injects an HTTP Basic Auth header.
class _BasicAuthInterceptor extends Interceptor {
  _BasicAuthInterceptor(this._encoded);

  final String _encoded;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Basic $_encoded';
    handler.next(options);
  }
}

/// Interceptor that injects a proxy/gateway Basic Auth header only if one
/// isn't already set (e.g. by [_BasicAuthInterceptor] for service auth).
class _ProxyAuthInterceptor extends Interceptor {
  _ProxyAuthInterceptor(this._auth);

  final String _auth;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Authorization', () => _auth);
    handler.next(options);
  }
}

/// Interceptor that follows 307/308 redirects for non-GET requests.
/// Dio only auto-follows redirects for GET; this handles POST/PUT/DELETE.
class _RedirectInterceptor extends Interceptor {
  _RedirectInterceptor(this._dio);

  final Dio _dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    if ((statusCode == 307 || statusCode == 308) &&
        err.response?.headers['location'] != null) {
      final location = err.response!.headers['location']!.first;
      final options = err.requestOptions;
      options.path = location;
      // Re-issue the same request to the redirect target
      _dio.fetch(options).then(
            (r) => handler.resolve(r),
            onError: (e) => handler.reject(e as DioException),
          );
      return;
    }
    handler.next(err);
  }
}

/// Interceptor that converts [DioException] into [ApiError].
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final message = err.response?.statusMessage ?? err.message ?? err.type.name;
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiError(message: message, statusCode: statusCode),
        response: err.response,
        type: err.type,
      ),
    );
  }
}

/// Toggles between local (LAN) and remote URL for a given instance id.
/// `true` = use localUrl (home network); `false` = use baseUrl (remote).
final useLocalUrlProvider = StateProvider.family<bool, int>(
  (ref, instanceId) => false,
);

/// Creates a [Dio] instance configured for a given [Instance].
///
/// If [overrideBaseUrl] or [instance.baseUrl] contains embedded
/// `user:pass@host` credentials, they are stripped from the URL and injected
/// as an `Authorization: Basic` header. For services that already send their
/// own Basic Auth (e.g. rTorrent, NZBGet), the service auth takes precedence
/// via [_BasicAuthInterceptor]; the proxy auth is only set as a fallback via
/// [_ProxyAuthInterceptor].
Dio buildDioForInstance(Instance instance, {String? overrideBaseUrl}) {
  final rawUrl = overrideBaseUrl ?? instance.baseUrl;
  final (:url, :basicAuth) = extractUrlCredentials(rawUrl);

  final dio = Dio(
    BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  final type = ServiceType.values.byName(instance.serviceType);
  final authInterceptor = type.usesBasicAuth
      ? _BasicAuthInterceptor(base64.encode(utf8.encode(instance.apiKey)))
      : _ApiKeyInterceptor(instance.apiKey);

  dio.interceptors.addAll([
    authInterceptor,
    if (basicAuth != null) _ProxyAuthInterceptor(basicAuth),
    _RedirectInterceptor(dio),
    _ErrorInterceptor(),
  ]);

  return dio;
}

/// Riverpod family provider — one [Dio] client per [Instance].
/// Rebuilds automatically when [useLocalUrlProvider] toggles.
final dioProvider = Provider.family<Dio, Instance>((ref, instance) {
  final useLocal = ref.watch(useLocalUrlProvider(instance.id));
  final localUrl = instance.localUrl;
  final effectiveUrl =
      (useLocal && localUrl != null && localUrl.isNotEmpty) ? localUrl : null;
  return buildDioForInstance(instance, overrideBaseUrl: effectiveUrl);
});
