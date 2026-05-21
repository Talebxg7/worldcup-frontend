import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  static const String localeKey = 'profile_language_code';

  LocaleNotifier() : super('en') {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(localeKey) ?? 'en';
  }

  Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    state = code;
    await prefs.setString(localeKey, code);
  }

  bool get isArabic => state == 'ar';
}
