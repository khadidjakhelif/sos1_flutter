import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sos1/models/medical_profile.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.67:8000'; // use 10.0.2.2 for Android emulator, or your PC IP for real device

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Exposes the configured [Dio] instance (with auth interceptor) for
  /// callers that need custom request options (e.g. binary downloads).
  Dio get dio => _dio;

  ApiService() {
    // Add JWT token to every request automatically
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} — ${error.message}');
        handler.next(error);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String employeeId,
    required String password,
    required String companyCode,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'employee_id': employeeId,
      'password': password,
      'company_code': companyCode.toUpperCase(),
    });
    final data = response.data['data'];
    await _saveToken(data['access_token']);
    await _saveUserId(data['user']['id']);
    await _saveCompanyId(data['user']['company_id']);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String employeeId,
    required String password,
    required String phone,
    required String companyCode,
    String? unit,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'employee_id': employeeId,
      'password': password,
      'phone': phone,
      'company_code': companyCode.toUpperCase(),
      if (unit != null && unit.isNotEmpty) 'unit': unit,
    });
    final data = response.data['data'];
    await _saveToken(data['access_token']);
    await _saveUserId(data['user']['id']);
    await _saveCompanyId(data['user']['company_id']);
    return data;
  }

  // ── Emergency ─────────────────────────────────────────────────────────────

  // CHANGED: returns the created emergency data (id, company_id) so callers
  // can set up SSE subscriptions. Still silently fails on network error.
  Future<Map<String, dynamic>?> reportEmergency({
    required String type,
    required String severity,
    double? latitude,
    double? longitude,
    String? locationDescription,
    String? voiceTranscript,
  }) async {
    // Map flutter's lowercase emergency types to the backend's allowed EMERGENCY_TYPES
    String mappedType;
    switch (type.toLowerCase()) {
      case 'cardiac':
        mappedType = 'Cardiac';
        break;
      case 'medical':
        mappedType = 'Medical';
        break;
      case 'bleeding':
        mappedType = 'Trauma';
        break;
      case 'choking':
        mappedType = 'Respiratory';
        break;
      case 'unconscious':
        mappedType = 'Neurological';
        break;
      case 'fire':
        mappedType = 'Fire';
        break;
      case 'police':
        mappedType = 'Police';
        break;
      default:
        mappedType = 'Medical'; // Default fallback
    }

    final response = await _dio.post('/emergencies', data: {
      'type': mappedType,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'location_description': locationDescription,
      if (voiceTranscript != null && voiceTranscript.isNotEmpty)
        'voice_transcript': voiceTranscript,
    });
    print(response.data);
    print('from the api ');
    // Return the `data` sub-object so the viewmodel can read id + company_id
    return response.data?['data'] as Map<String, dynamic>?;
  }

  Future<void> resolveEmergency(String emergencyId) async {
    await _dio.put('/emergencies/$emergencyId/resolve', data: {
      'status': 'resolved',
    });
  }

  /// Sends a GPS heartbeat for [emergencyId].
  /// Called every ~30 s by EmergencyHeartbeatService while emergency is active.
  /// Also acts as an interaction signal (updates last_seen_active on backend).
  /// PRIVACY NOTE: called only while an active emergency is in progress.
  Future<void> sendGpsHeartbeat({
    required String emergencyId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dio.post('/emergencies/$emergencyId/heartbeat', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (_) {} // silent fail — heartbeat is best-effort
  }

  /// Worker acknowledges an "are you OK?" ping from the officer.
  Future<bool> acknowledgePing(String emergencyId) async {
    try {
      final response = await _dio.post('/emergencies/$emergencyId/ping-ack');
      print('[ApiService] acknowledgePing success: ${response.statusCode}');
      return true;
    } catch (e) {
      print('[ApiService] acknowledgePing FAILED for $emergencyId: $e');
      return false;
    }
  }

  // ── Worker Heartbeat ──────────────────────────────────────────────────────

  Future<void> updateUserHeartbeat(double lat, double lng) async {
    await _dio.put(
      '/users/heartbeat',
      data: {
        'latitude': lat,
        'longitude': lng,
      },
    );
  }

  // ── Medical Profile ───────────────────────────────────────────────────────

  Future<void> syncMedicalProfile(MedicalProfile profile) async {
    await _dio.put('/users/medical-profile', data: {
      'blood_type': profile.bloodType.displayName,
      'is_universal_donor': profile.isUniversalDonor,
      'chronic_diseases': profile.chronicDiseases,
      'allergies': profile.allergies,
      'emergency_notes': profile.emergencyNotes,
      'ice_contact_name': profile.iceContact?.name ?? '',
      'ice_contact_relation': profile.iceContact?.relation ?? '',
      'ice_contact_phone': profile.iceContact?.phoneNumber ?? '',
    });
  }

  Future<Map<String, dynamic>?> getMedicalProfile(String userId) async {
    try {
      final res = await _dio.get('/medical/$userId');
      return res.data?['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEmergencyHistory() async {
    return _handleRequest(() async {
      final res =
          await _dio.get('/emergencies', queryParameters: {'user_id': 'me'});
      if (res.data['data'] != null && res.data['data']['items'] != null) {
        return List<Map<String, dynamic>>.from(res.data['data']['items']);
      }
      return [];
    });
  }

  Future<List<Map<String, dynamic>>> getActiveCompanyEmergencies() async {
    return _handleRequest(() async {
      final res =
          await _dio.get('/emergencies', queryParameters: {'status': 'active'});
      if (res.data['data'] != null && res.data['data']['items'] != null) {
        return List<Map<String, dynamic>>.from(res.data['data']['items']);
      }
      return [];
    });
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMessages(String emergencyId) async {
    return _handleRequest(() async {
      final res = await _dio.get('/emergencies/$emergencyId/messages');
      if (res.data['data'] != null) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }
      return [];
    });
  }

  // ── Keep alive ────────────────────────────────────────────────────────────

  Future<void> sendTextMessage(String emergencyId, String content) async {
    await _handleRequest(() async {
      await _dio.post(
        '/emergencies/$emergencyId/messages/text',
        data: {'content': content},
      );
    });
  }

  /// Send a text message with an explicit sender_role (e.g. 'ai_assistant', 'system').
  /// Fire-and-forget: errors are silently ignored.
  Future<void> sendTextMessageWithRole(
      String emergencyId, String content, String senderRole) async {
    try {
      await _dio.post(
        '/emergencies/$emergencyId/messages/text',
        data: {'content': content, 'sender_role': senderRole},
      );
    } catch (e) {
      print('[ApiService] fire-and-forget sendTextMessageWithRole failed: $e');
    }
  }

  Future<void> sendVoiceMessage(String emergencyId, String filePath) async {
    await _handleRequest(() async {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath,
            filename: 'voice_message.m4a'),
      });
      await _dio.post(
        '/emergencies/$emergencyId/messages/voice',
        data: formData,
      );
    });
  }

  // ── FCM ───────────────────────────────────────────────────────────────────

  Future<void> registerFcmToken(String token, String deviceInfo) async {
    try {
      await _dio.post('/users/fcm-tokens', data: {
        'token': token,
        'device_info': deviceInfo,
      });
    } catch (_) {} // Silent fail
  }

  Future<void> deleteFcmToken(String token) async {
    try {
      await _dio.delete('/users/fcm-tokens/$token');
    } catch (_) {} // Silent fail
  }

  Future<void> updateLastSeen() async {
    try {
      await _dio.put('/users/last-seen');
    } catch (_) {} // silent fail
  }

  // ── Live location ─────────────────────────────────────────────────────────────

  /// Reports the worker's current GPS position to the backend.
  /// Called periodically by [LocationTrackingService] while the app is foregrounded.
  /// Silent-fails so a momentary network hiccup never surfaces to the user.
  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      await _dio.put('/users/heartbeat', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (_) {} // silent fail — do not interrupt user workflow
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Executes [request] and returns its result.
  /// Re-throws [DioException] so callers can handle HTTP errors,
  /// while any other exception is also propagated.
  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      print(
          '_handleRequest DioError: ${e.response?.statusCode} — ${e.message}');
      rethrow;
    } catch (e) {
      print('_handleRequest error: $e');
      rethrow;
    }
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _saveCompanyId(String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_id', companyId);
  }

  Future<String?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('company_id');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove('company_id');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
