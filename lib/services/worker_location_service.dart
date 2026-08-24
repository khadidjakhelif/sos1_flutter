import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sos1/services/api_service.dart';

/// Sends periodic GPS heartbeats to the backend when ANY company emergency is active.
///
/// This layer works alongside the `unit` match logic to find nearby ordinary workers.
/// Privacy: Only tracks location while an emergency is active in the company.
class WorkerLocationService {
  static const Duration _interval = Duration(seconds: 30);
  
  final ApiService _api;
  final Set<String> _activeEmergencies = {};
  Timer? _timer;

  WorkerLocationService(this._api);

  bool get isRunning => _timer != null;
  int get activeCount => _activeEmergencies.length;

  /// Starts the heartbeat if an emergency started and it wasn't already running.
  void start(String emergencyId) {
    _activeEmergencies.add(emergencyId);
    if (_timer == null) {
      _sendHeartbeat();
      _timer = Timer.periodic(_interval, (_) => _sendHeartbeat());
    }
  }

  /// Stops the heartbeat if the resolved emergency was the last active one.
  void stop(String emergencyId) {
    _activeEmergencies.remove(emergencyId);
    if (_activeEmergencies.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }
  
  /// Clears all state and stops the timer (e.g. on logout or disconnect)
  void stopAll() {
    _activeEmergencies.clear();
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _sendHeartbeat() async {
    try {
      final token = await _api.getToken();
      if (token == null) return; // not logged in

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // No permission, skip silently
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await _api.updateUserHeartbeat(pos.latitude, pos.longitude);
    } catch (e) {
      print('[WorkerLocationService] Failed to send heartbeat: $e');
    }
  }
}
