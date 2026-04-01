import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

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

/// Creates a [Dio] instance configured for a given [Instance].
Dio buildDioForInstance(Instance instance) {
  final dio = Dio(
    BaseOptions(
      baseUrl: instance.baseUrl,
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

  dio.interceptors.addAll([
    _ApiKeyInterceptor(instance.apiKey),
    _RedirectInterceptor(dio),
    _ErrorInterceptor(),
  ]);

  return dio;
}

/// Riverpod family provider — one [Dio] client per [Instance].
final dioProvider = Provider.family<Dio, Instance>((ref, instance) {
  return buildDioForInstance(instance);
});
