import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/contacts_service.dart';

/// Professional Emergency Actions Service
/// Handles SMS alerts (background via native channel), phone calls, and GPS location
class EmergencyActionsService with ListenableServiceMixin {
  // Native platform channel for background SMS
  static const _smsChannel = MethodChannel('com.sos1.sms/send');

  // Cached location for instant access during emergencies
  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  // Status tracking
  final ReactiveValue<String> _lastActionStatus = ReactiveValue<String>('');
  String get lastActionStatus => _lastActionStatus.value;

  EmergencyActionsService() {
    _cacheLocationPeriodically();
  }

  // ─────────────────────────────────────────
  // CALL — dials the actual number passed in
  // ─────────────────────────────────────────
  Future<bool> callNumber(String number) async {
    try {
      final cleanNumber = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final uri = Uri.parse('tel:$cleanNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _lastActionStatus.value = '📞 Appel lancé vers $cleanNumber';
        notifyListeners();
        return true;
      } else {
        _lastActionStatus.value = '❌ Impossible de lancer l\'appel';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastActionStatus.value = '❌ Erreur d\'appel: $e';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────
  // SMS — sends directly in background via native channel
  // ─────────────────────────────────────────

  /// Send SOS SMS with location to ALL emergency contacts that have SMS enabled
  Future<SmsResult> sendSOSToAllContacts({
    required String emergencyType,
    String? customMessage,
  }) async {
    // 1. Check SMS permission
    final hasPermission = await _requestSmsPermission();
    if (!hasPermission) {
      _lastActionStatus.value = '❌ Permission SMS refusée';
      notifyListeners();
      return SmsResult(success: false, sentCount: 0, failedCount: 0, message: 'Permission SMS refusée');
    }

    // 2. Get location
    final locationText = await _getLocationText();

    // 3. Build the message
    final body = _buildSosMessage(emergencyType, locationText, customMessage);

    // 4. Get all contacts with SMS enabled
    final contactsService = locator<ContactsService>();
    final smsContacts = contactsService.personalContacts
        .where((c) => c.smsAlertEnabled)
        .toList();

    if (smsContacts.isEmpty) {
      _lastActionStatus.value = '⚠️ Aucun contact SMS activé';
      notifyListeners();
      return SmsResult(success: false, sentCount: 0, failedCount: 0, message: 'Aucun contact avec alerte SMS activée');
    }

    // 5. Send SMS to each contact via native channel
    int sentCount = 0;
    int failedCount = 0;

    for (final contact in smsContacts) {
      final cleanNumber = contact.phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final success = await _sendSmsNative(cleanNumber, body);
      if (success) {
        sentCount++;
      } else {
        failedCount++;
      }
    }

    _lastActionStatus.value = '✅ SMS envoyé à $sentCount contact(s)${failedCount > 0 ? ', $failedCount échec(s)' : ''}';
    notifyListeners();

    return SmsResult(
      success: sentCount > 0,
      sentCount: sentCount,
      failedCount: failedCount,
      message: _lastActionStatus.value,
    );
  }

  /// Send a single SMS via the native Android platform channel
  Future<bool> _sendSmsNative(String phoneNumber, String message) async {
    try {
      final result = await _smsChannel.invokeMethod('sendSms', {
        'phone': phoneNumber,
        'message': message,
      });
      return result == true;
    } on PlatformException {
      // If native channel fails, try fallback
      return false;
    }
  }

  /// Legacy method — kept for backward compatibility
  Future<void> sendSOSWithLocation({
    required String emergencyType,
    String? customMessage,
  }) async {
    await sendSOSToAllContacts(
      emergencyType: emergencyType,
      customMessage: customMessage,
    );
  }

  // ─────────────────────────────────────────
  // AUTO-CALL contacts with autoCallEnabled
  // ─────────────────────────────────────────
  Future<void> autoCallFirstContact() async {
    final contactsService = locator<ContactsService>();
    final autoCallContacts = contactsService.personalContacts
        .where((c) => c.autoCallEnabled)
        .toList();

    if (autoCallContacts.isNotEmpty) {
      await callNumber(autoCallContacts.first.phoneNumber);
    }
  }

  // ─────────────────────────────────────────
  // FULL SOS SEQUENCE: SMS all + Call first
  // ─────────────────────────────────────────
  Future<void> triggerFullSOS({
    required String emergencyType,
    String? customMessage,
  }) async {
    // Step 1: Send SMS to ALL contacts (background, no user tap)
    await sendSOSToAllContacts(
      emergencyType: emergencyType,
      customMessage: customMessage,
    );

    // Step 2: Auto-call the first contact with auto-call enabled
    await autoCallFirstContact();
  }

  // ─────────────────────────────────────────
  // GPS HELPERS
  // ─────────────────────────────────────────
  Future<String> _getLocationText() async {
    // 1. Request location permission explicitly
    await _requestLocationPermission();

    // 2. Try to get a fresh position
    final pos = await _getLocation();
    if (pos != null) {
      _lastKnownPosition = pos;
      final lat = pos.latitude.toStringAsFixed(6);
      final lng = pos.longitude.toStringAsFixed(6);
      return 'https://maps.google.com/?q=$lat,$lng';
    }

    // 3. Use cached position as fallback
    if (_lastKnownPosition != null) {
      final lat = _lastKnownPosition!.latitude.toStringAsFixed(6);
      final lng = _lastKnownPosition!.longitude.toStringAsFixed(6);
      return 'https://maps.google.com/?q=$lat,$lng';
    }

    return 'Position GPS indisponible';
  }

  Future<Position?> _getLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      // Check/request permission via Geolocator
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }
      if (perm == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      // Try getLastKnownPosition first (instant, no GPS wait)
      final lastKnown = await Geolocator.getLastKnownPosition();

      // Then try getCurrentPosition for a fresh fix
      try {
        final fresh = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        return fresh;
      } catch (_) {
        // If fresh GPS times out, return last known
        return lastKnown;
      }
    } catch (_) {
      // Final fallback
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Cache location every 30 seconds for instant access
  void _cacheLocationPeriodically() {
    _updateCachedLocation();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      await _updateCachedLocation();
      return true;
    });
  }

  Future<void> _updateCachedLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      // Try instant last known first
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _lastKnownPosition = lastKnown;
      }

      // Then try fresh position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      _lastKnownPosition = pos;
    } catch (_) {}
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
  }

  // ─────────────────────────────────────────
  // PERMISSION HELPERS
  // ─────────────────────────────────────────
  Future<bool> _requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (status.isGranted) return true;
    status = await Permission.sms.request();
    return status.isGranted;
  }

  // ─────────────────────────────────────────
  // MESSAGE BUILDER
  // ─────────────────────────────────────────
  String _buildSosMessage(String emergencyType, String locationText, String? customMessage) {
    return '🆘 URGENCE SOS - $emergencyType\n'
        '${customMessage != null && customMessage.isNotEmpty ? '$customMessage\n' : ''}'
        '📍 Ma position: $locationText\n'
        'Envoyé depuis SOS Algérie.';
  }
}

/// Result of an SMS sending operation
class SmsResult {
  final bool success;
  final int sentCount;
  final int failedCount;
  final String message;

  SmsResult({
    required this.success,
    required this.sentCount,
    required this.failedCount,
    required this.message,
  });
}