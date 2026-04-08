import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/language_service.dart';
import 'package:sos1/models/language.dart';

import '../voice_assistant/voice_assistant_view.dart';

class LanguageSelectionViewModel extends BaseViewModel {
  final _languageService = locator<LanguageService>();
  final _navigationService = locator<NavigationService>();

  AppLanguage get selectedLanguage => _languageService.currentLanguage;
  bool get isFrench => _languageService.isFrench;
  bool get isArabic => _languageService.isArabic;
  bool get isEnglish => _languageService.isEnglish;

  Future<void> selectLanguage(AppLanguage language) async {
    await _languageService.setLanguage(language);
    notifyListeners();
  }

  void continueToApp() {
    _navigationService.navigateTo('/');
  }

  void goBack() {
    _navigationService.back();
  }
}
