enum AppLanguage {
  french,
  arabic,
  english,
}

extension AppLanguageExtension on AppLanguage {
  /// Display name in native language
  String get displayName {
    switch (this) {
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.arabic:
        return 'العربية';
      case AppLanguage.english:
        return 'English';
    }
  }

  /// ISO 639-1 language code
  String get code {
    switch (this) {
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
        return 'en';
    }
  }

  /// Key used in LanguageProvider
  String get key {
    switch (this) {
      case AppLanguage.french:
        return 'Francais';
      case AppLanguage.arabic:
        return 'العربية';
      case AppLanguage.english:
        return 'English';
    }
  }

  /// Check if language is RTL (Right-to-Left)
  bool get isRTL => this == AppLanguage.arabic;

  /// Get locale string (e.g., 'fr_FR', 'ar_DZ', 'en_US')
  String get locale {
    switch (this) {
      case AppLanguage.french:
        return 'fr_FR';
      case AppLanguage.arabic:
        return 'ar_DZ';
      case AppLanguage.english:
        return 'en_US';
    }
  }

  /// Get flag emoji
  String get flag {
    switch (this) {
      case AppLanguage.french:
        return '🇫🇷';
      case AppLanguage.arabic:
        return '🇩🇿';
      case AppLanguage.english:
        return '🇬🇧';
    }
  }

  /// Get localized welcome text
  String get welcomeText {
    switch (this) {
      case AppLanguage.french:
        return 'Bienvenue';
      case AppLanguage.arabic:
        return 'مرحبا';
      case AppLanguage.english:
        return 'Welcome';
    }
  }

  /// Get localized emergency text
  String get emergencyText {
    switch (this) {
      case AppLanguage.french:
        return 'URGENCE';
      case AppLanguage.arabic:
        return 'طوارئ';
      case AppLanguage.english:
        return 'EMERGENCY';
    }
  }
}

/// Helper function to convert from language code
AppLanguage languageFromCode(String code) {
  switch (code.toLowerCase()) {
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

/// Helper function to convert from LanguageProvider key
AppLanguage languageFromKey(String key) {
  switch (key) {
    case 'Francais':
      return AppLanguage.french;
    case 'العربية':
      return AppLanguage.arabic;
    case 'English':
      return AppLanguage.english;
    default:
      return AppLanguage.french;
  }
}

/// List of all supported languages
const List<AppLanguage> supportedLanguages = [
  AppLanguage.french,
  AppLanguage.arabic,
  AppLanguage.english,
];