import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sos1/models/medical_profile.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.85:8000'; // use 10.0.2.2 for Android emulator, or your PC IP for real device
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

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
    await _saveToken(response.data['data']['access_token']);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String employeeId,
    required String password,
    required String phone,
    required String companyCode,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'employee_id': employeeId,
      'password': password,
      'phone': phone,
      'company_code': companyCode.toUpperCase(),
    });
    await _saveToken(response.data['data']['access_token']);
    return response.data['data'];
  }

  // ── Emergency ─────────────────────────────────────────────────────────────

  Future<void> reportEmergency({
    required String type,
    required String severity,
    double? latitude,
    double? longitude,
    String? locationDescription,
  }) async {
    await _dio.post('/emergencies', data: {
      'type': type,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'location_description': locationDescription,
    });
  }

  Future<void> resolveEmergency(String emergencyId) async {
    await _dio.put('/emergencies/$emergencyId/resolve', data: {
      'status': 'resolved',
    });
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

  // ── Keep alive ────────────────────────────────────────────────────────────

  Future<void> updateLastSeen() async {
    try {
      await _dio.put('/users/last-seen');
    } catch (_) {} // silent fail
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
