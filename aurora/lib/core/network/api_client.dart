/// 📁 lib/core/network/api_client.dart
/// Centralized API client using Dio with interceptors for:
/// 1. JWT injection from Supabase Auth
/// 2. Debug logging
/// 3. Retry on 5xx/timeout (3 attempts)
/// 4. Centralized error parsing
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env_config.dart';

// ─────────────────────────────────────────────────────
// API Exceptions
// ─────────────────────────────────────────────────────

/// Structured API error thrown by the client.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// True for rate-limit or auth errors where retry won't help.
  bool get isAuthError => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
}

// ─────────────────────────────────────────────────────
// Auth Interceptor
// ─────────────────────────────────────────────────────

/// Injects the Supabase JWT into every request.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }
}

// ─────────────────────────────────────────────────────
// Logging Interceptor (debug only)
// ─────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────
// Logging Interceptor (Robust Debugging)
// ─────────────────────────────────────────────────────

class RobustLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🌐 API REQ: ${options.method} ${options.uri}');
      debugPrint('🌐 Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('🌐 Body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🌐 API RES: ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('🌐 Body: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🛑 API ERR: ${err.type} ${err.requestOptions.uri}');
      debugPrint('🛑 Message: ${err.message}');
      if (err.response != null) {
        debugPrint('🛑 Res Status: ${err.response?.statusCode}');
        debugPrint('🛑 Res Body: ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────
// Retry Interceptor
// ─────────────────────────────────────────────────────

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isRetryable = (statusCode != null && statusCode >= 500) ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    if (!isRetryable) {
      handler.next(err);
      return;
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    err.requestOptions.extra['retryCount'] = retryCount + 1;
    final delay = Duration(milliseconds: 500 * (retryCount + 1));

    if (kDebugMode) {
      debugPrint('↻ Retry ${retryCount + 1}/$maxRetries after ${delay.inMilliseconds}ms');
    }

    await Future.delayed(delay);

    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

// ─────────────────────────────────────────────────────
// Error Parsing Interceptor
// ─────────────────────────────────────────────────────

class ErrorParsingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    String message = 'Connection failed. Check your network.';
    int? code = response?.statusCode;

    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // FastAPI error format: {"detail": {"error": "..."}}
        final detail = data['detail'];
        if (detail is Map<String, dynamic>) {
          message = detail['error'] as String? ?? 'Unknown error';
        } else if (detail is String) {
          message = detail;
        } else {
          message = data['error'] as String? ??
              data['message'] as String? ??
              'Server error ($code)';
        }
      } else {
        message = 'Server error ($code)';
      }
    } else {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          message = 'Connection timed out. Try again.';
        case DioExceptionType.receiveTimeout:
          message = 'Server took too long to respond.';
        case DioExceptionType.cancel:
          message = 'Request cancelled.';
        default:
          message = err.message ?? 'Connection failed.';
      }
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(message, statusCode: code, data: response?.data),
        message: message,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// API Client
// ─────────────────────────────────────────────────────

/// Singleton Dio client configured with all interceptors.
class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Order matters: auth → retry → error parsing → logging
    dio.interceptors.addAll([
      AuthInterceptor(),
      RetryInterceptor(dio: dio, maxRetries: EnvConfig.maxRetries),
      ErrorParsingInterceptor(),
      RobustLogInterceptor(),
    ]);
  }

  // ── Convenience methods ─────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
  }) {
    return dio.post<T>(path,
        data: data, queryParameters: queryParameters, options: options,
        onSendProgress: onSendProgress);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.patch<T>(path, data: data, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.delete<T>(path, data: data, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.put<T>(path, data: data, options: options);
  }
}

// ─────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────

/// Singleton API client provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
