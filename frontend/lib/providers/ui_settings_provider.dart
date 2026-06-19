import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/ui_settings.dart';
import '../utils/constants.dart';

class UiSettingsProvider extends ChangeNotifier {
  UiSettings _settings = const UiSettings();
  bool _isLoaded = false;

  UiSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  UiSettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/ui-settings'));
      if (response.statusCode == 200) {
        _settings = UiSettings.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error loading UI settings: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> saveSettings(UiSettings settings, String? token) async {
    final response = await http.put(
      Uri.parse('${AppConstants.apiUrl}/ui-settings'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode(settings.toJson()),
    );
    if (response.statusCode == 200) {
      _settings = UiSettings.fromJson(json.decode(response.body));
      notifyListeners();
      return true;
    }
    return false;
  }
}
