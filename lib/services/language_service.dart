import 'package:stacked/stacked.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

class LanguageService with ListenableServiceMixin {
  final ReactiveValue<AppLanguage> _currentLanguage = ReactiveValue<AppLanguage>(AppLanguage.french);

  AppLanguage get currentLanguage => _currentLanguage.value;
  bool get isFrench => _currentLanguage.value == AppLanguage.french;
  bool get isArabic => _currentLanguage.value == AppLanguage.arabic;
  bool get isEnglish => _currentLanguage.value == AppLanguage.english;

  // Key for SharedPreferences
  static const String _languageKey = 'selected_language';

  LanguageService() {
    listenToReactiveValues([_currentLanguage]);
    //_initializeLanguage();
  }

  /// Initialize language from saved preferences
  Future<void> _initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      print('💾 Saved language code: $savedLanguageCode');

      if (savedLanguageCode != null) {
        // Convert saved code to AppLanguage
        _currentLanguage.value = _getLanguageFromCode(savedLanguageCode);
      } else {
        // Default to French
        _currentLanguage.value = AppLanguage.french;
      }
    } catch (e) {
      print('Error loading language: $e');
      _currentLanguage.value = AppLanguage.french;
    }
  }

  /// Load language from SharedPreferences (public method)
  Future<void> loadLanguage() async {
    await _initializeLanguage();
  }

  /// Set language and save to SharedPreferences
  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage.value = language;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
    } catch (e) {
      print('Error saving language: $e');
    }

    notifyListeners();
  }

  /// Toggle between all three languages (French -> Arabic -> English -> French)
  Future<void> toggleLanguage() async {
    AppLanguage nextLanguage;

    switch (_currentLanguage.value) {
      case AppLanguage.french:
        nextLanguage = AppLanguage.arabic;
        break;
      case AppLanguage.arabic:
        nextLanguage = AppLanguage.english;
        break;
      case AppLanguage.english:
        nextLanguage = AppLanguage.french;
        break;
    }

    await setLanguage(nextLanguage);
  }

  /// Get language display name
  String getLanguageName() {
    return _currentLanguage.value.displayName;
  }

  /// Get language code (fr, ar, en)
  String getLanguageCode() {
    return _currentLanguage.value.code;
  }

  /// Convert language code string to AppLanguage
  AppLanguage _getLanguageFromCode(String code) {
    switch (code) {
      case 'fr':
        return AppLanguage.french;
      case 'ar':
        return AppLanguage.arabic;
      case 'en':
        return AppLanguage.english;
      default:
        return AppLanguage.french;
    }
  }

  /// Check if current language is RTL (Right-to-Left)
  bool get isRTL => _currentLanguage.value.isRTL;

  /// Clear saved language preference
  Future<void> clearLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      _currentLanguage.value = AppLanguage.french;
      notifyListeners();
    } catch (e) {
      print('Error clearing language preference: $e');
    }
  }
}