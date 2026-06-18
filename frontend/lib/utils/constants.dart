class AppConstants {
  static const String _defaultBaseUrl = 'https://hello-homes-production.up.railway.app';

  // Override at build time with:
  // flutter build web --dart-define=API_BASE_URL=https://api.example.com
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _configuredBaseUrl.trim().isEmpty
      ? _defaultBaseUrl
      : _configuredBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
  static String get apiUrl => '$baseUrl/api';
}
