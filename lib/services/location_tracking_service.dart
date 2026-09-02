import 'dart:async';

import 'package:stacked/stacked.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/api_service.dart';
import 'package:sos1/services/emergency_actions_service.dart';

/// Periodically reports the worker's live GPS position to the backend.
///
/// Design notes:
/// - Reuses the position already cached by [EmergencyActionsService] every 30 s,
///   so zero extra GPS hardware calls are made.
/// - Sends a PUT /users/location every [_intervalSeconds] seconds while the
///   app is in the foreground (tracking stops when [stop] is called or the
///   app is disposed).
/// - Silent-fails on every network error — never surfaces to the user.
class LocationTrackingService with ListenableServiceMixin {
  static const int _intervalSeconds = 15;

  final _api = locator<ApiService>();
  final _emergencyActions = locator<EmergencyActionsService>();

  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  /// Start the periodic location reporting.
  /// Idempotent — calling start() while already running is a no-op.
  void start() {
    if (_running) return;
    _running = true;
    notifyListeners();

    // Send immediately on first start so the map shows the worker right away.
    _sendLocation();

    _timer = Timer.periodic(
      const Duration(seconds: _intervalSeconds),
      (_) => _sendLocation(),
    );
  }

  /// Stop the periodic location reporting.
  /// Call this on logout or when tracking should cease.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    notifyListeners();
  }

  Future<void> _sendLocation() async {
    // Read from the position already cached by EmergencyActionsService.
    // This avoids any extra GPS requests.
    final pos = _emergencyActions.lastKnownPosition;
    if (pos == null) return; // no fix yet — skip silently

    await _api.updateLocation(pos.latitude, pos.longitude);
  }

  void dispose() {
    stop();
  }
}
