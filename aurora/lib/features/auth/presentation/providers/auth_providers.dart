import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ===========================================
// DEPENDENCY INJECTION PROVIDERS
// ===========================================

/// Provides the Supabase client instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the auth remote data source.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

/// Provides the auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// ===========================================
// AUTH STATE
// ===========================================

/// Possible authentication states.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication state class.
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      // Clear error when loading starts or explicitly requested
      errorMessage: clearError || status == AuthStatus.loading
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

// ===========================================
// AUTH NOTIFIER
// ===========================================

/// StateNotifier for managing authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState());

  /// Check if user is already logged in.
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.getCurrentUser();

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  /// Login with email and password.
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.loginWithEmailPassword(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  /// Register with email and password.
  Future<void> register(String email, String password, String displayName) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.registerWithEmailPassword(
      email: email,
      password: password,
      displayName: displayName,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  /// Logout current user.
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    await _authRepository.logout();

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      clearError: true,
    );
  }

  /// Clear any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ===========================================
// MAIN AUTH PROVIDER
// ===========================================

/// Main authentication provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Convenience provider for current user.
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for auth status.
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
