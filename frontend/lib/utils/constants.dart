class AppConstants {
  // Defaults to the current Laravel host so Railway can serve the Flutter app
  // and API from the same public URL. Override at build time with:
  // flutter build web --dart-define=API_BASE_URL=https://api.example.com
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _configuredBaseUrl;
  static String get apiUrl => '$baseUrl/api';
}
