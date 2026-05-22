import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/user_profile.dart';

class ProfileService {
  final SupabaseClient _client;
  ProfileService(this._client);

  Future<UserProfile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> createProfile(UserProfile profile) async {
    await _client.from('profiles').insert(profile.toJson());
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').update({
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'phone_number': profile.phoneNumber,
      'location': profile.location,
      'designation': profile.designation,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profile.id);
  }
}
