// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i9;
import 'package:flutter/material.dart';
import 'package:sos1/ui/views/emergency_contacts/emergency_contacts_view.dart'
    as _i3;
import 'package:sos1/ui/views/emergency_mode/emergency_mode_view.dart' as _i8;
import 'package:sos1/ui/views/language_selection/language_selection_view.dart'
    as _i5;
import 'package:sos1/ui/views/medical_profile/medical_profile_view.dart' as _i4;
import 'package:sos1/ui/views/settings/settings_view.dart' as _i6;
import 'package:sos1/ui/views/sos_history/sos_history_view.dart' as _i7;
import 'package:sos1/ui/views/voice_assistant/voice_assistant_view.dart' as _i2;
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i10;

class Routes {
  static const voiceAssistantView = '/';

  static const emergencyContactsView = '/emergency-contacts-view';

  static const medicalProfileView = '/medical-profile-view';

  static const languageSelectionView = '/language-selection-view';

  static const settingsView = '/settings-view';

  static const sOSHistoryView = '/s-os-history-view';

  static const emergencyModeView = '/emergency-mode-view';

  static const all = <String>{
    voiceAssistantView,
    emergencyContactsView,
    medicalProfileView,
    languageSelectionView,
    settingsView,
    sOSHistoryView,
    emergencyModeView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.voiceAssistantView,
      page: _i2.VoiceAssistantView,
    ),
    _i1.RouteDef(
      Routes.emergencyContactsView,
      page: _i3.EmergencyContactsView,
    ),
    _i1.RouteDef(
      Routes.medicalProfileView,
      page: _i4.MedicalProfileView,
    ),
    _i1.RouteDef(
      Routes.languageSelectionView,
      page: _i5.LanguageSelectionView,
    ),
    _i1.RouteDef(
      Routes.settingsView,
      page: _i6.SettingsView,
    ),
    _i1.RouteDef(
      Routes.sOSHistoryView,
      page: _i7.SOSHistoryView,
    ),
    _i1.RouteDef(
      Routes.emergencyModeView,
      page: _i8.EmergencyModeView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.VoiceAssistantView: (data) {
      return _i9.MaterialPageRoute<dynamic>(
        builder: (context) => const _i2.VoiceAssistantView(),
        settings: data,
      );
    },
    _i3.EmergencyContactsView: (data) {
      return _i9.MaterialPageRoute<dynamic>(
        builder: (context) => const _i3.EmergencyContactsView(),
        settings: data,
      );
    },
    _i4.MedicalProfileView: (data) {
      return _i9.MaterialPageRoute<dynamic>(
        builder: (context) => const _i4.MedicalProfileView(),
        settings: data,
      );
    },
    _i5.LanguageSelectionView: (data) {
      return _i9.MaterialPageRoute<dynamic>(
        builder: (context) => const _i5.LanguageSelectionView(),
        settings: data,
      );
    },
    _i6.SettingsView: (data) {
      return _i9.MaterialPageRoute<dynamic>(
        builder: (context) => const _i6.SettingsView(),
        settings: data,
      );
    },
    _i7.SOSHistoryView: (data) {
      return _i9.MaterialPageRoute<dynamic>(
        builder: (context) => const _i7.SOSHistoryView(),
        settings: data,
      );
    },
    _i8.EmergencyModeView: (data) {
      final args = data.getArgs<EmergencyModeViewArguments>(nullOk: false);
      return _i9.MaterialPageRoute<dynamic>(
        builder: (context) => _i8.EmergencyModeView(
            key: args.key,
            emergencyType: args.emergencyType,
            emergencyDescription: args.emergencyDescription,
            location: args.location),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class EmergencyModeViewArguments {
  const EmergencyModeViewArguments({
    this.key,
    required this.emergencyType,
    this.emergencyDescription,
    this.location,
  });

  final _i9.Key? key;

  final String emergencyType;

  final String? emergencyDescription;

  final String? location;

  @override
  String toString() {
    return '{"key": "$key", "emergencyType": "$emergencyType", "emergencyDescription": "$emergencyDescription", "location": "$location"}';
  }

  @override
  bool operator ==(covariant EmergencyModeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.emergencyType == emergencyType &&
        other.emergencyDescription == emergencyDescription &&
        other.location == location;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        emergencyType.hashCode ^
        emergencyDescription.hashCode ^
        location.hashCode;
  }
}

extension NavigatorStateExtension on _i10.NavigationService {
  Future<dynamic> navigateToVoiceAssistantView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.voiceAssistantView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToEmergencyContactsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.emergencyContactsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToMedicalProfileView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.medicalProfileView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToLanguageSelectionView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.languageSelectionView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSettingsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.settingsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSOSHistoryView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.sOSHistoryView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToEmergencyModeView({
    _i9.Key? key,
    required String emergencyType,
    String? emergencyDescription,
    String? location,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.emergencyModeView,
        arguments: EmergencyModeViewArguments(
            key: key,
            emergencyType: emergencyType,
            emergencyDescription: emergencyDescription,
            location: location),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVoiceAssistantView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.voiceAssistantView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithEmergencyContactsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.emergencyContactsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithMedicalProfileView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.medicalProfileView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithLanguageSelectionView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.languageSelectionView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSettingsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.settingsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSOSHistoryView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.sOSHistoryView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithEmergencyModeView({
    _i9.Key? key,
    required String emergencyType,
    String? emergencyDescription,
    String? location,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.emergencyModeView,
        arguments: EmergencyModeViewArguments(
            key: key,
            emergencyType: emergencyType,
            emergencyDescription: emergencyDescription,
            location: location),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
