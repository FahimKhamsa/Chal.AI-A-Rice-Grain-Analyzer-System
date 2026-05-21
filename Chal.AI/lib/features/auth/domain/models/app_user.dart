import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory AppUser.fromSupabaseUser(User user) {
    final meta = user.userMetadata;
    return AppUser(
      id: user.id,
      email: user.email,
      displayName: meta?['full_name'] as String? ?? meta?['name'] as String?,
      avatarUrl: meta?['avatar_url'] as String?,
    );
  }
}
