
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _remoteDataSource.signIn(email, password);
    } catch (e) {
      throw Exception(e.toString()); // Simplify error for UI
    }
  }

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      return await _remoteDataSource.signUp(email, password);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e) {
       throw Exception(e.toString());
    }
  }

  Future<void> createProfile(String userId, String displayName) async {
     try {
       await _remoteDataSource.createProfile(userId, displayName);
     } catch (e) {
       throw Exception(e.toString());
     }
  }

  Session? getCurrentSession() {
    return _remoteDataSource.getCurrentSession();
  }
}
