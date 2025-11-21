import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageService {
  static const String _languageKey = 'app_language';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getLanguage() async {
    try {
      return await _storage.read(key: _languageKey);
    } catch (e) {
      print('Error reading language preference: $e');
      return null;
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _storage.write(key: _languageKey, value: language);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  Future<bool> isEnglish() async {
    final language = await getLanguage();
    return language == 'en';
  }
}

