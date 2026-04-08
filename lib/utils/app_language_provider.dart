import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'Francais';

  String get currentLanguage => _currentLanguage;

  // Your translations map
  final translations = {
    'Francais': {
      'back': 'Retour',
      'save': 'Sauvgarder',
      'life_critical_emergency_service': 'SERVICE D\'URGENCE CIVILE',
      'Algerian_Democratic_and_Popular_Republic': 'RÉPUBLIQUE ALGÉRIENNE DÉMOCRATIQUE ET POPULAIRE',
      'app_name': 'SOS ALGÉRIE',
      'language': 'LANGAGE',
      'selected': 'SÉLECTIONNÉ',
      'french': 'Français',
      'arabic': 'العربية',
      'english': 'English',
      'settings': 'Paramètres',
      'home': 'Accueil',
      'profile': 'Profil',
      'about': 'À propos',
      'help': 'Aide',
      'logout': 'Déconnexion',
      'next': 'Suivant',
      'account_security': 'COMPTE ET SÉCURITÉ',
      'app_preferences': 'PRÉFÉRENCES APPLICATION',
      'medical_profile': 'Profil Médical',
      'medical_profile_subtitle': 'Groupe sanguin, allergies...',
      'emergency_contacts': 'Contacts d\'Urgence',
      'emergency_contacts_subtitle': 'Personnes à prévenir',
      'language_subtitle': 'Sélection(Français/English/العربية)',
      'location_sharing': 'Partage de Localisation (SMS)',
      'location_sharing_subtitle': 'Envoi automatique du GPS',
      'sos_history': 'Historique des SOS',
      'sos_history_subtitle': 'Consulter les alertes passées',
      'emergency_number': "Numéro d'urgence",
    },
    'العربية': {
      'back': 'عودة',
      'save': 'حفظ',
      'life_critical_emergency_service': 'خدمة الطوارئ',
      'Algerian_Democratic_and_Popular_Republic': 'الجمهورية الجزائرية الديمقراطية الشعبية',
      'app_name': 'SOS الجزائر',
      'language': 'اللغة',
      'selected': 'تم اختياره',
      'french': 'Français',
      'arabic': 'العربية',
      'english': 'English',
      'settings': 'الإعدادات',
      'home': 'الرئيسية',
      'profile': 'الملف الشخصي',
      'about': 'حول',
      'help': 'مساعدة',
      'logout': 'تسجيل الخروج',
      'next': 'التالي',
      'account_security': 'الحساب والأمان',
      'app_preferences': 'تفضيلات التطبيق',
      'medical_profile': 'الملف الطبي',
      'medical_profile_subtitle': 'فصيلة الدم، الحساسية...',
      'emergency_contacts': 'جهات الاتصال للطوارئ',
      'emergency_contacts_subtitle': 'الأشخاص الذين يجب إخطارهم',
      'language_subtitle': 'اختيار(Français/English/العربية)',
      'location_sharing': 'مشاركة الموقع (SMS)',
      'location_sharing_subtitle': 'إرسال GPS تلقائي',
      'sos_history': 'سجل SOS',
      'sos_history_subtitle': 'عرض التنبيهات السابقة',
      'emergency_number': 'رقم الطوارئ',
    },
    'English': {
      'back': 'Back',
      'save': 'Save',
      'life_critical_emergency_service': 'LIFE-CRITICAL EMERGENCY SERVICE',
      'Algerian_Democratic_and_Popular_Republic': 'ALGERIAN DEMOCRATIC AND POPULAR REPUBLIC',
      'app_name': 'SOS ALGERIA',
      'selected': 'SELECTED',
      'french': 'Français',
      'arabic': 'العربية',
      'english': 'English',
      'settings': 'Settings',
      'home': 'Home',
      'profile': 'Profile',
      'about': 'About',
      'help': 'Help',
      'logout': 'Logout',
      'next': 'Next',
      'account_security': 'ACCOUNT & SECURITY',
      'app_preferences': 'APP PREFERENCES',
      'medical_profile': 'Medical Profile',
      'medical_profile_subtitle': 'Blood type, allergies...',
      'emergency_contacts': 'Emergency Contacts',
      'emergency_contacts_subtitle': 'People to notify',
      'language': 'Language',
      'language_subtitle': 'Selection(Français/English/العربية)',
      'location_sharing': 'Location Sharing (SMS)',
      'location_sharing_subtitle': 'Automatic GPS sending',
      'sos_history': 'SOS History',
      'sos_history_subtitle': 'View past alerts',
      'emergency_number': 'Emergency number',
    },
  };

  // Load saved language from storage
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selected_language') ?? 'Francais';
    notifyListeners();
  }

  // Change language and save to storage
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', language);
    notifyListeners(); // This updates all widgets listening
  }

  // Get translated text
  String translate(String key) {
    return translations[_currentLanguage]?[key] ?? key;
  }

  // Helper to check if current language is RTL
  bool get isRTL => _currentLanguage == 'العربية';
}