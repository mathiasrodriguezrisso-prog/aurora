/// Base class for all failures in the application.
/// Used by repositories to return errors in a type-safe manner.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message (code: $code)';
}

/// Server-related failures (API errors, network issues)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  // Common auth failure factory constructors
  factory AuthFailure.invalidCredentials() =>
      const AuthFailure('Invalid email or password', code: 'invalid_credentials');

  factory AuthFailure.emailAlreadyInUse() =>
      const AuthFailure('Email is already registered', code: 'email_exists');

  factory AuthFailure.weakPassword() =>
      const AuthFailure('Password is too weak', code: 'weak_password');

  factory AuthFailure.userNotFound() =>
      const AuthFailure('User not found', code: 'user_not_found');

  factory AuthFailure.sessionExpired() =>
      const AuthFailure('Session has expired. Please log in again.', code: 'session_expired');
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Cache/Local storage failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}
