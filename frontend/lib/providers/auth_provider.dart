import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'hello_homes_auth_token';
  static const _userKey = 'hello_homes_auth_user';
  static const _isAdminKey = 'hello_homes_auth_is_admin';

  String? _token;
  Map<String, dynamic>? _user;
  bool _isAdmin = false;
  bool _isLoadingSession = true;
  String? _lastAuthError;
  String? _lastAuthDebugMessage;

  AuthProvider() {
    _loadSession();
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isLoadingSession => _isLoadingSession;
  String? get lastAuthError => _lastAuthError;
  String? get lastAuthDebugMessage => _lastAuthDebugMessage;

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final encodedUser = prefs.getString(_userKey);

      if (token != null && encodedUser != null) {
        _token = token;
        _user = json.decode(encodedUser) as Map<String, dynamic>;
        _isAdmin = prefs.getBool(_isAdminKey) ?? false;
      }
    } catch (e) {
      debugPrint('Error loading auth session: $e');
      await _clearPersistedSession();
      _token = null;
      _user = null;
      _isAdmin = false;
    } finally {
      _isLoadingSession = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    if (_token == null || _user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, json.encode(_user));
    await prefs.setBool(_isAdminKey, _isAdmin);
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_isAdminKey);
  }

  Future<bool> checkEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/auth/check-email?email=$email'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] == true;
      }
    } catch (e) {
      debugPrint('Error checking email: $e');
    }
    return false;
  }

  Future<String?> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        return null;
      } else {
        return data['message'] ?? 'Failed to send OTP. Please try again.';
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return 'Failed to send OTP. Please check your network connection.';
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _lastAuthError = null;
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        _user = data['user'];
        _isAdmin = data['is_admin'] ?? false;
        await _persistSession();
        notifyListeners();
        return true;
      }

      _lastAuthError = _extractErrorMessage(response.body, 'Invalid or expired OTP.');
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      _lastAuthError = 'Unable to verify OTP. Please check your connection and try again.';
    }
    return false;
  }

  Future<bool> adminLogin(String email, String password) async {
    _lastAuthError = null;
    _lastAuthDebugMessage = null;
    final adminLoginUrl = Uri.parse('${AppConstants.apiUrl}/auth/admin-login');
    debugPrint('ADMIN LOGIN frontend request: POST $adminLoginUrl');

    try {
      final response = await http.post(
        adminLoginUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      _lastAuthDebugMessage = 'POST $adminLoginUrl returned ${response.statusCode}';
      debugPrint('ADMIN LOGIN frontend response: $_lastAuthDebugMessage');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        _user = data['user'];
        _isAdmin = data['is_admin'] ?? false;
        await _persistSession();
        notifyListeners();
        return _isAdmin;
      }

      _lastAuthError = _extractErrorMessage(
        response.body,
        'Admin login failed with HTTP ${response.statusCode}.',
      );
    } catch (e) {
      _lastAuthDebugMessage = 'POST $adminLoginUrl failed before receiving a response';
      debugPrint('Error logging in as admin at $adminLoginUrl: $e');
      _lastAuthError = 'Unable to reach admin login endpoint $adminLoginUrl. Please check the deployed API URL, network, and CORS settings.';
    }
    return false;
  }

  String _extractErrorMessage(String responseBody, String fallback) {
    try {
      final data = json.decode(responseBody);
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    } catch (_) {
      // Use the safe fallback below when the server response is not JSON.
    }
    return fallback;
  }

  Future<bool> fetchUser() async {
    if (_token == null) return false;
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        _user = json.decode(response.body);
        await _persistSession();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    return false;
  }

  void setSession(String token, Map<String, dynamic> user, {bool isAdmin = false}) {
    _token = token;
    _user = user;
    _isAdmin = isAdmin;
    _persistSession();
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    _isAdmin = false;
    _lastAuthError = null;
    _lastAuthDebugMessage = null;
    _clearPersistedSession();
    notifyListeners();
  }
}
