
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  Future<void> createProfile(String userId, String displayName) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Handle or rethrow. If trigger handles creation, this might fail or be redundant.
      // Assuming manual creation is requested as per instructions.
      print("Profile creation error: $e");
      throw Exception("Failed to create profile: $e");
    }
  }
}
