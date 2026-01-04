class ApiConfig {
  // API Base URL
  static const String baseUrl = 'https://web-production-3495.up.railway.app';
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String productsEndpoint = '/api/products';
  static const String usersEndpoint = '/api/users';
  static const String uploadEndpoint = '/api/upload';
  
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
