import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

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

  Future<bool> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
    }
    return false;
  }

  Future<bool> verifyOtp(String email, String otp) async {
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
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
    }
    return false;
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
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    return false;
  }

  void setSession(String token, Map<String, dynamic> user) {
    _token = token;
    _user = user;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    _isAdmin = false;
    notifyListeners();
  }
}
