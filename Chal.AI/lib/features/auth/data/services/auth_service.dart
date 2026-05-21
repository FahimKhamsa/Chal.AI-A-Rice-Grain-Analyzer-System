import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/app_user.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  Stream<AppUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        return user != null ? AppUser.fromSupabaseUser(user) : null;
      });

  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    return user != null ? AppUser.fromSupabaseUser(user) : null;
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'com.chalai.chalai://login-callback/',
    );
    if (res.user == null) throw Exception('Sign-up failed: no user returned.');
    return AppUser.fromSupabaseUser(res.user!);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Sign-in failed.');
    return AppUser.fromSupabaseUser(res.user!);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'com.chalai.chalai://reset-callback/',
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
