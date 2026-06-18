class AppConstants {
  static const String _defaultBaseUrl = 'https://hello-homes-production.up.railway.app';

  // Override at build time with:
  // flutter build web --dart-define=API_BASE_URL=https://api.example.com
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Railway environment variables must be passed into Flutter at build time with
  // --dart-define; web builds cannot read container/runtime env vars directly.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String supabaseProductBucket =
      String.fromEnvironment('SUPABASE_PRODUCT_BUCKET');

  static String get baseUrl => _configuredBaseUrl.trim().isEmpty
      ? _defaultBaseUrl
      : _configuredBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
  static String get apiUrl => '$baseUrl/api';
}
