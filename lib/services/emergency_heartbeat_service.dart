import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sos1/services/api_service.dart';

/// Sends conditional GPS heartbeats to the backend while an emergency is active.
///
/// Lifecycle:
///   • start(emergencyId) — called once the emergency is confirmed by the backend.
///   • stop()             — called immediately on resolve, cancel, or app dispose.
///
/// PRIVACY NOTE: Location is only collected and transmitted during an active
/// emergency. There is NO background/continuous tracking at any other time.
/// A full user-consent UI (showing when/why location is being shared) is
/// planned as a separate task.
class EmergencyHeartbeatService {
  static const Duration _interval = Duration(seconds: 30);

  final ApiService _api;

  Timer?  _timer;
  String? _activeEmergencyId;

  bool get isRunning => _timer != null;

  EmergencyHeartbeatService(this._api);

  /// Starts the 30-second heartbeat timer for [emergencyId].
  /// Idempotent — calling start() again while already running is a no-op.
  void start(String emergencyId) {
    if (_timer != null) return; // already running
    _activeEmergencyId = emergencyId;
    // Send one immediately, then every 30 s
    _sendHeartbeat();
    _timer = Timer.periodic(_interval, (_) => _sendHeartbeat());
  }

  /// Stops the heartbeat immediately.
  /// Must be called on emergency resolve, cancel, or viewmodel dispose.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _activeEmergencyId = null;
  }

  Future<void> _sendHeartbeat() async {
    final id = _activeEmergencyId;
    if (id == null) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // No permission — skip silently; the app should have requested
        // permission when the emergency was first created.
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await _api.sendGpsHeartbeat(
        emergencyId: id,
        latitude:    pos.latitude,
        longitude:   pos.longitude,
      );
    } catch (e) {
      // Heartbeat is best-effort; never crash the emergency session.
      print('[HeartbeatService] Skipped heartbeat: $e');
    }
  }
}
