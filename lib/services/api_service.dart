import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    if (_authToken != null) {
      return ApiConfig.getAuthHeaders(_authToken!);
    }
    return ApiConfig.headers;
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'username': username,
        }),
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Register error: $e');
    }
  }

  // Product Methods
  Future<List<Product>> getProducts({int? limit, String? category}) async {
    try {
      String url = '${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}';
      
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (category != null) queryParams['category'] = category;
      
      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsList = data['products'] ?? data['data'] ?? data;
        return productsList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get products error: $e');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/$id'),
        headers: _headers,
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['product'] ?? data);
      } else {
        throw Exception('Failed to load product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get product error: $e');
    }
  }

  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String url,
    String? category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'imageUrl': imageUrl,
          'url': url,
          'category': category,
        }),
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['product'] ?? data);
      } else {
        throw Exception('Failed to create product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create product error: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/$id'),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete product error: $e');
    }
  }

  Future<Product> likeProduct(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/$id/like'),
        headers: _headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['product'] ?? data);
      } else {
        throw Exception('Failed to like product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Like product error: $e');
    }
  }

  // User Methods
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/$userId'),
        headers: _headers,
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user'] ?? data);
      } else {
        throw Exception('Failed to load user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  Future<UserModel> updateUserProfile({
    required String userId,
    String? name,
    String? username,
    String? photoUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (username != null) body['username'] = username;
      if (photoUrl != null) body['photoUrl'] = photoUrl;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/$userId'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user'] ?? data);
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update user error: $e');
    }
  }

  // Search
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}/search?q=$query'),
        headers: _headers,
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsList = data['products'] ?? data['results'] ?? data;
        return productsList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products: ${response.body}');
      }
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }
}
