import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract for authentication operations.
/// Implemented by AuthRepositoryImpl in the data layer.
abstract class AuthRepository {
  /// Sign in with email and password.
  Future<Either<Failure, UserEntity>> loginWithEmailPassword({
    required String email,
    required String password,
  });

  /// Create new account with email and password.
  Future<Either<Failure, UserEntity>> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign out the current user.
  Future<Either<Failure, void>> logout();

  /// Get the currently authenticated user.
  /// Returns failure if no user is logged in.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Check if a user is currently logged in.
  bool get isLoggedIn;
}
