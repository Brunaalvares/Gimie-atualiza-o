class ApiConfig {
  // API Base URL - Gimie API 2.0 on Vercel
  static const String baseUrl = 'https://api2gimie.vercel.app';
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String productsEndpoint = '/api/products';
  static const String usersEndpoint = '/api/users';
  static const String uploadEndpoint = '/api/upload';
  
  // Scraping Endpoints (Gimie API 2.0)
  static const String scrapeEndpoint = '/api/products';
  static const String extractEndpoint = '/api/products/extract';
  static const String suggestionsEndpoint = '/api/products/suggestions';
  static const String healthEndpoint = '/health';
  static const String currencyEndpoint = '/api/products/exchange-rates';
  static const String convertEndpoint = '/api/products/convert';
  
  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}
