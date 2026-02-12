/// Base exception for server/API errors.
/// Thrown by DataSources, caught by Repositories.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ServerException(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'ServerException: $message (status: $statusCode, code: $code)';
}

/// Exception for authentication errors from Supabase.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Exception for local cache/storage errors.
class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Exception for network connectivity issues.
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}
