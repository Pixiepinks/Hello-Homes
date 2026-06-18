class AppConstants {
  static const String _defaultBaseUrl = 'https://hello-homes-production.up.railway.app';

  // Override at build time with:
  // flutter build web --dart-define=API_BASE_URL=https://api.example.com
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _configuredBaseUrl.trim().isEmpty
      ? _defaultBaseUrl
      : _configuredBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
  static String get apiUrl => '$baseUrl/api';

  // Supabase Storage configuration for admin product image uploads.
  // Override at build time with:
  // flutter build web --dart-define=SUPABASE_URL=https://project.supabase.co \
  //   --dart-define=SUPABASE_ANON_KEY=... \
  //   --dart-define=SUPABASE_PRODUCT_BUCKET=product-images
  static const String _configuredSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _configuredSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _configuredSupabaseProductBucket = String.fromEnvironment(
    'SUPABASE_PRODUCT_BUCKET',
    defaultValue: 'product-images',
  );

  static String get supabaseUrl => _configuredSupabaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
  static String get supabaseAnonKey => _configuredSupabaseAnonKey.trim();
  static String get supabaseProductBucket => _configuredSupabaseProductBucket.trim().isEmpty
      ? 'product-images'
      : _configuredSupabaseProductBucket.trim();
  static bool get isSupabaseStorageConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && supabaseProductBucket.isNotEmpty;
}
