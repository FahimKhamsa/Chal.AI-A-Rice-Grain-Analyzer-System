import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/profile_service.dart';
import '../../domain/models/user_profile.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(Supabase.instance.client);
});

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return ref.read(profileServiceProvider).fetchProfile(user.id);
  }

  Future<void> create(UserProfile profile) async {
    await ref.read(profileServiceProvider).createProfile(profile);
    ref.invalidateSelf();
  }

  Future<void> saveUpdate(UserProfile profile) async {
    await ref.read(profileServiceProvider).updateProfile(profile);
    ref.invalidateSelf();
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);
