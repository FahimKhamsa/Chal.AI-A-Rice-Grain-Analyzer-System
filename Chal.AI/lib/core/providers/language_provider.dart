import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'app_language';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLangKey);
    if (saved != null && (saved == 'en' || saved == 'bn')) {
      state = saved;
    }
  }

  Future<void> toggle() async {
    final next = state == 'en' ? 'bn' : 'en';
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, next);
  }

  Future<void> setLanguage(String lang) async {
    if (lang == state) return;
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, lang);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
