import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Remote data source for authentication operations.
/// Interacts directly with Supabase Auth and profiles table.
abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmailPassword(String email, String password);
  Future<UserModel> registerWithEmailPassword(String email, String password, String displayName);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  bool get isLoggedIn;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> loginWithEmailPassword(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Login failed: No user returned');
      }

      // Fetch profile data
      final profile = await _fetchProfile(response.user!.id);

      return UserModel.fromSupabaseAuth(response.user!, profile: profile);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName, 'full_name': displayName},
      );

      if (response.user == null) {
        throw const AuthException('Registration failed: No user returned');
      }

      // Profile is created automatically by trigger, but fetch it to confirm
      await Future.delayed(const Duration(milliseconds: 500));
      final profile = await _fetchProfile(response.user!.id);

      return UserModel.fromSupabaseAuth(response.user!, profile: profile);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final profile = await _fetchProfile(user.id);
      return UserModel.fromSupabaseAuth(user, profile: profile);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  bool get isLoggedIn => client.auth.currentUser != null;

  /// Helper to fetch profile from profiles table.
  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      // Profile might not exist yet, return null
      return null;
    }
  }
}
