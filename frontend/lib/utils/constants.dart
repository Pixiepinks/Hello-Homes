class AppConstants {
  // Use localhost for local development (127.0.0.1 can sometimes cause CORS issues in some browsers)
  // CHANGE THIS TO YOUR LIVE DOMAIN (e.g., https://api.hellohomes.com) when deploying
  static const String baseUrl = 'http://localhost:8000';
  static const String apiUrl = '$baseUrl/api';
}
