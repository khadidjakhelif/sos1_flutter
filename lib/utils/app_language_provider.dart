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
      'ai_used': "IA Utilisé",
      'emergency_mode_activated': 'Lancement du mode urgence...',
      'modify': 'Modifier',
      'vital_information': 'Informations Vitales',
      'rapid_calls':'APPELS RAPIDES',
      'how_can_i_help':'Comment puis-je vous aider ?',
      'voice_assistant_active':'ASSISTANT VOCAL ACTIF',
      'example': '"J\'ai besoin d\'une ambulance à Alger Centre, une personne est inconsciente..."',
      'samu':'SAMU',
      'police':'Police',
      'fire_department':'Pompiers',
      'civil_protection':'Protection Civil',
      'listening': 'Je vous écoute...',
      'helpIsComing':'L\'aide est en route.',
      'emergencyDetected':'Urgence détectée !',
      'processing':'Traitement en cours...',
      'fire_emergency':'Urgence Incendie',
      'police_emergency':'Urgence Police',
      'medical_emergency':'Urgence Médicale',
      'please_try_again':'Veuillez réessayer',
      'speech_not_available':'Reconnaissance vocale non disponible',
      'mic_permission_denied':'Permission microphone refusée',
      'ai_processing':'Analyse IA en cours...',
      'app_subtitle':'Assistant IA',
      'privacy_policy':'politique de confidentialité',
      'terms_of_use':'Conditions d\'utilisation',
      'privacy_policy_subtitle':'Informations sur la collecte et la confidentialité des données',
      'terms_of_use_subtitle':'Règles et directives d’utilisation de l’application',
      'data_collected': 'Données Collectées',
      'data_voice': 'Voix',
      'data_voice_sub': 'Processée localement, jamais stockée',
      'data_location': 'Localisation',
      'data_location_sub': 'Uniquement pendant SOS',
      'data_history': 'Historique SOS',
      'data_history_sub': 'Stocké sur VOTRE appareil',
      'data_name_phone': 'Nom/Téléphone',
      'data_name_phone_sub': 'JAMAIS collecté',
      'no_ads': 'Pas de publicité',
      'no_data_sale': 'Pas de vente de données',
      'no_tracking': 'Pas de suivi utilisateur',
      'local_storage': '100% Stockage local',
      'your_rights': 'Vos Droits',
      'right_delete': 'Supprimer tout',
      'right_export': 'Exporter historique',
      'right_location_off': 'Désactiver localisation',
      'contact_us': 'Nous Contacter',
      'contact_project': 'Projet PFE Master - Incubateur BBA University\nAlgérie',
      'last_updated': 'Dernière mise à jour: Avril 2026',
      'footer_project': 'Projet PFE Master',
      'footer_university': 'Incubateur BBA University',
      'footer_credits': 'Développé par étudiants Master\nPour la sécurité des Algériens\n© 2026 SOS Algérie',
      'terms_of_use': 'Conditions d\'utilisation',
      'emergency_numbers_title': 'NUMÉROS D\'URGENCE - ALGÉRIE',
      'disclaimer_title': 'IMPORTANT - Avertissement',
      'disclaimer_body':
      '• L\'application fournit une ASSISTANCE uniquement\n'
          '• Ne remplace PAS les services professionnels\n'
          '• L\'IA donne des conseils généraux\n'
          '• Toujours appeler directement les secours\n'
          '• Utilisation à vos propres risques',
      'responsibilities_title': 'Vos Responsabilités',
      'responsibilities_body':
      '• Tester régulièrement l\'application\n'
          '• Garder le téléphone chargé\n'
          '• Activer la localisation précise\n'
          '• Suivre les instructions avec prudence\n'
          '• Appeler directement en cas de doute',
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
      'ai_used': "تم استخدام الذكاء الاصطناعي",
      'emergency_mode_activated': 'تم تفعيل وضع الطوارئ...',
      'modify': 'تعدبل',
      'vital_information': 'معلومات حيوية',
      'rapid_calls':'اتصالات السريعة',
      'how_can_i_help':'كيف يمكنني مساعدتك؟',
      'voice_assistant_active':'مساعد صوتي نشط',
      'example': '"أحتاج سيارة إسعاف في وسط الجزائر، شخص ما فاقد للوعي..."',
      'samu':'SAMU',
      'police':'الشرطة',
      'fire_department':'رجال الإطفاء',
      'civil_protection':'الحماية المدنية',
      'listening': 'أنا أستمع...',
      'help_is_coming':'L\'aide est en route.',
      'emergency_detected':'Urgence détectée !',
      'processing':'Traitement en cours...',
      'fire_emergency':'حالة طوارئ حريق',
      'police_emergency':'حالة طوارئ شرطية',
      'medical_emergency':'حالة طوارئ طبية',
      'please_try_again':'يرجى المحاولة مرة أخرى',
      'speech_not_available':'التعرف على الكلام غير متاح',
      'mic_permission_denied':'تم رفض إذن استخدام الميكروفون',
      'ai_processing':'تحليل الذكاء الاصطناعي قيد التقدم...',
      'app_subtitle':'مساعد IA',
      'privacy_policy':'سياسة الخصوصية',
      'terms_of_use':'شروط الاستخدام',
      'privacy_policy_subtitle':'تفاصيل حول جمع البيانات والخصوصية',
      'terms_of_use_subtitle':'قواعد وإرشادات استخدام التطبيق',
      'data_collected': 'البيانات المجمّعة',
      'data_voice': 'الصوت',
      'data_voice_sub': 'تُعالَج محلياً، لا تُخزَّن أبداً',
      'data_location': 'الموقع',
      'data_location_sub': 'فقط أثناء SOS',
      'data_history': 'سجل SOS',
      'data_history_sub': 'مخزَّن على جهازك فقط',
      'data_name_phone': 'الاسم/الهاتف',
      'data_name_phone_sub': 'لا يُجمَّع أبداً',
      'no_ads': 'لا إعلانات',
      'no_data_sale': 'لا بيع للبيانات',
      'no_tracking': 'لا تتبع للمستخدم',
      'local_storage': '100% تخزين محلي',
      'your_rights': 'حقوقك',
      'right_delete': 'حذف كل شيء',
      'right_export': 'تصدير السجل',
      'right_location_off': 'تعطيل الموقع',
      'contact_us': 'اتصل بنا',
      'contact_project': 'مشروع ماجستير - حاضنة جامعة BBA\nالجزائر',
      'last_updated': 'آخر تحديث: أبريل 2026',
      'footer_project': 'مشروع ماجستير',
      'footer_university': 'حاضنة جامعة BBA',
      'footer_credits': 'طوّره طلاب الماجستير\nلأمن الجزائريين\n© 2026 SOS الجزائر',
      'terms_of_use': 'شروط الاستخدام',
      'emergency_numbers_title': 'أرقام الطوارئ - الجزائر',
      'disclaimer_title': 'مهم - تنبيه',
      'disclaimer_body':
      '• التطبيق يقدم مساعدة فقط\n'
          '• لا يُعوِّض الخدمات المهنية\n'
          '• الذكاء الاصطناعي يقدم نصائح عامة\n'
          '• اتصل دائماً بالإسعاف مباشرة\n'
          '• الاستخدام على مسؤوليتك',
      'responsibilities_title': 'مسؤولياتك',
      'responsibilities_body':
      '• اختبر التطبيق بانتظام\n'
          '• احتفظ بالهاتف مشحوناً\n'
          '• فعّل الموقع الدقيق\n'
          '• اتبع التعليمات بحذر\n'
          '• اتصل مباشرة عند الشك',
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
      'ai_used': "AI Used",
      'emergency_mode_activated': 'Emergency mode activated...',
      'modify': 'Modify',
      'vital_information': 'Vital Information',
      'rapid_calls':'RAPID CALLS',
      'how_can_i_help':'How can I help you ?',
      'voice_assistant_active':'ACTIVE VOICE ASSISTANT',
      'example': '"I need an ambulance in Algiers Centre, someone is unconscious..."',
      'samu':'Emergency Medical Services',
      'police':'Police',
      'fire_department':'Fire Department',
      'civil_protection':'Civil Protection',
      'listening': 'I am listening...',
      'helpIsComing':'Help is on the way',
      'emergencyDetected':'Emergency Detected !',
      'processing':'Traitement en cours...',
      'fire_emergency':'fire Emergency',
      'police_emergency':'police Emergency',
      'medical_emergency':'medical Emergency',
      'please_try_again':'Please try again',
      'speech_not_available':'Speech recognition not available',
      'mic_permission_denied':'Microphone permission denied',
      'ai_processing':'AI Processing...',
      'app_subtitle':'AI Assistant',
      'privacy_policy':'Privacy Policy',
      'terms_of_use':'Terms of use',
      'privacy_policy_subtitle':'Details on data collection and privacy',
      'terms_of_use_subtitle':'Rules and guidelines for using the app',
      'data_collected': 'Data Collected',
      'data_voice': 'Voice',
      'data_voice_sub': 'Processed locally, never stored',
      'data_location': 'Location',
      'data_location_sub': 'Only during SOS',
      'data_history': 'SOS History',
      'data_history_sub': 'Stored on YOUR device',
      'data_name_phone': 'Name/Phone',
      'data_name_phone_sub': 'NEVER collected',
      'no_ads': 'No advertising',
      'no_data_sale': 'No data selling',
      'no_tracking': 'No user tracking',
      'local_storage': '100% Local storage',
      'your_rights': 'Your Rights',
      'right_delete': 'Delete everything',
      'right_export': 'Export history',
      'right_location_off': 'Disable location',
      'contact_us': 'Contact Us',
      'contact_project': 'Master PFE Project - BBA University Incubator\nAlgeria',
      'last_updated': 'Last updated: April 2026',
      'footer_project': 'Master PFE Project',
      'footer_university': 'BBA University Incubator',
      'footer_credits': 'Developed by Master students\nFor the safety of Algerians\n© 2026 SOS Algeria',
      'terms_of_use': 'Terms of Use',
      'emergency_numbers_title': 'EMERGENCY NUMBERS - ALGERIA',
      'disclaimer_title': 'IMPORTANT - Warning',
      'disclaimer_body':
      '• The app provides ASSISTANCE only\n'
          '• Does NOT replace professional services\n'
          '• AI gives general advice\n'
          '• Always call emergency services directly\n'
          '• Use at your own risk',
      'responsibilities_title': 'Your Responsibilities',
      'responsibilities_body':
      '• Test the app regularly\n'
          '• Keep your phone charged\n'
          '• Enable precise location\n'
          '• Follow instructions carefully\n'
          '• Call directly if in doubt',
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