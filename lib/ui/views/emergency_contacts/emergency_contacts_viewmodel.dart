import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/models/medical_profile.dart';
import 'package:sos1/services/api_service.dart';

class EmergencyContactsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _apiService = locator<ApiService>();

  List<ICEContact> _contacts = [];
  String? _errorMessage;

  List<ICEContact> get iceContacts => List.unmodifiable(_contacts);
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    setBusy(true);
    _errorMessage = null;

    // Load from Hive first (fast, offline-capable)
    final box = Hive.box<MedicalProfile>('medicalProfile');
    final profile = box.get('profile');
    if (profile?.iceContact != null) {
      _contacts = [profile!.iceContact!];
    }

    // Refresh from backend
    try {
      final userId = await _apiService.getUserId();
      if (userId != null) {
        final data = await _apiService.getMedicalProfile(userId);
        if (data != null) {
          final name = data['ice_contact_name'] as String? ?? '';
          final relation = data['ice_contact_relation'] as String? ?? '';
          final phone = data['ice_contact_phone'] as String? ?? '';
          if (name.isNotEmpty) {
            _contacts = [ICEContact(name: name, relation: relation, phoneNumber: phone)];
          } else {
            _contacts = [];
          }
        }
      }
    } catch (e) {
      debugPrint('ICE fetch error: $e');
      // Keep Hive data — do not surface the error on load
    }

    setBusy(false);
    notifyListeners();
  }

  Future<void> addContact(ICEContact contact) async {
    _errorMessage = null;
    // For now we only support one ICE contact (backend schema has one)
    _contacts = [contact];
    notifyListeners();
    await _persist();
  }

  Future<void> updateContact(int index, ICEContact contact) async {
    _errorMessage = null;
    _contacts[index] = contact;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteContact(int index) async {
    _errorMessage = null;
    _contacts.removeAt(index);
    notifyListeners();
    await _persist();
  }

  /// Saves contacts to both Hive and the backend medical profile.
  Future<void> _persist() async {
    final ice = _contacts.isNotEmpty ? _contacts.first : null;

    // 1. Update Hive
    final box = Hive.box<MedicalProfile>('medicalProfile');
    final existing = box.get('profile');
    if (existing != null) {
      await box.put('profile', existing.copyWith(iceContact: ice));
    }

    // 2. Sync to backend
    try {
      final userId = await _apiService.getUserId();
      if (userId != null) {
        final profileData = await _apiService.getMedicalProfile(userId);
        if (profileData != null) {
          // Re-use existing profile data, only update ICE fields
          final updatedProfile = MedicalProfile.fromJson(profileData).copyWith(iceContact: ice);
          await _apiService.syncMedicalProfile(updatedProfile);
        }
      }
    } catch (e) {
      debugPrint('ICE sync error: $e');
      _errorMessage = 'Sauvegardé localement — sync réseau échouée';
      notifyListeners();
    }
  }

  void goBack() => _navigationService.back();
}
