// NEW file — dart:io chunked SSE client for the worker app.
// Opens GET /events/stream?company_id=…&token=… and emits
// EmergencyResolution objects when EMERGENCY_RESOLVED events arrive.
// No pub.dev dependencies — uses dart:io HttpClient only.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sos1/models/emergency_resolution.dart';
import 'package:sos1/services/api_service.dart';

class EmergencySseService {
  // Reuse the same base URL as ApiService
  static const String _baseUrl = ApiService.baseUrl;

  HttpClient? _httpClient;
  HttpClientRequest? _request;
  StreamController<EmergencyResolution>? _controller;
  StreamSubscription<String>? _lineSub;
  bool _connected = false;

  /// Stream of resolved-emergency events.
  /// The view-model subscribes to this after reporting the emergency.
  Stream<EmergencyResolution> get resolutionStream =>
      _controller?.stream ?? const Stream.empty();

  bool get isConnected => _connected;

  /// Opens the SSE connection for [companyId] using [token].
  Future<void> connect(String companyId, String token) async {
    // Idempotent: skip if already connected
    if (_connected) return;

    _controller = StreamController<EmergencyResolution>.broadcast();
    _httpClient = HttpClient();

    try {
      final uri = Uri.parse(
        '$_baseUrl/events/stream?company_id=$companyId&token=${Uri.encodeComponent(token)}',
      );

      _request = await _httpClient!.getUrl(uri);
      _request!.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      _request!.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

      final response = await _request!.close();
      _connected = true;

      // SSE messages arrive as UTF-8 text lines separated by \n\n
      final lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      // Buffer to accumulate the current event's data line
      String dataBuffer = '';

      _lineSub = lines.listen(
        (line) {
          if (line.startsWith('data: ')) {
            // Strip 'data: ' prefix and accumulate
            dataBuffer += line.substring(6);
          } else if (line.isEmpty && dataBuffer.isNotEmpty) {
            // Empty line = end of SSE event block — parse it
            _handleRawData(dataBuffer);
            dataBuffer = '';
          }
          // Ignore 'event:', 'id:', comment (':') lines for now
        },
        onError: (err) {
          print('[EmergencySseService] SSE stream error: $err');
          _connected = false;
        },
        onDone: () {
          print('[EmergencySseService] SSE stream closed');
          _connected = false;
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('[EmergencySseService] Failed to connect: $e');
      _connected = false;
    }
  }

  void _handleRawData(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final eventType = decoded['type'] as String?;

      // We only care about EMERGENCY_RESOLVED events
      if (eventType != 'EMERGENCY_RESOLVED') return;

      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) return;

      // The backend broadcasts the full _emergency_payload shape:
      // { emergency: {...}, user: {...}, ... }
      final emergencyJson = data['emergency'] as Map<String, dynamic>?;
      if (emergencyJson == null) return;

      final resolution = EmergencyResolution.fromJson(emergencyJson);
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(resolution);
      }
    } catch (e) {
      print('[EmergencySseService] Failed to parse SSE event: $e');
    }
  }

  /// Cleanly closes the SSE connection and stream.
  void disconnect() {
    _connected = false;
    _lineSub?.cancel();
    _lineSub = null;
    _request?.abort();
    _request = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    _controller?.close();
    _controller = null;
  }
}
