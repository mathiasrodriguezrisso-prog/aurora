
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';

// 1. Auth State Stream (for redirection)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 2. Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(AuthRemoteDataSource());
});

// 3. Auth State State
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthStateData {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthStateData({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthStateData copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthStateData(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// 4. Auth Notifier
class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthRepositoryImpl _repository;

  AuthNotifier(this._repository) : super(const AuthStateData());

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final session = _repository.getCurrentSession();
      if (session != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: session.user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
       state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.signIn(email, password);
      if (response.user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
      } else {
        state = state.copyWith(status: AuthStatus.error, errorMessage: "Login failed");
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.signUp(email, password);
      if (response.user != null) {
        // Create profile
        await _repository.createProfile(response.user!.id, displayName);
        state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
      } else {
         state = state.copyWith(status: AuthStatus.error, errorMessage: "Registration failed");
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signOut();
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
    } catch (e) {
       state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
