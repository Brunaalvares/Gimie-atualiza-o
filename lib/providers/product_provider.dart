import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  List<Product> _userProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;

  List<Product> get products => _products;
  List<Product> get userProducts => _userProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;

  // Load products from both API and Firebase
  Future<void> loadProducts({String? category}) async {
    _isLoading = true;
    _selectedCategory = category;
    notifyListeners();

    try {
      List<Product> allProducts = [];

      // Try to load from API first
      try {
        final apiProducts = await _apiService.getProducts(category: category);
        allProducts.addAll(apiProducts);
      } catch (e) {
        debugPrint('API load products error: $e');
      }

      // Load from Firebase
      try {
        final firebaseProducts = await _firebaseService.getProducts(category: category);
        
        // Merge products, avoiding duplicates
        for (var fbProduct in firebaseProducts) {
          if (!allProducts.any((p) => p.id == fbProduct.id)) {
            allProducts.add(fbProduct);
          }
        }
      } catch (e) {
        debugPrint('Firebase load products error: $e');
      }

      // Sort by creation date
      allProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _products = allProducts;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar produtos';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user's products
  Future<void> loadUserProducts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProducts = await _firebaseService.getUserProducts(userId);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar seus produtos';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add product
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String url,
    required String userId,
    String? category,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final product = Product(
        id: '',
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        url: url,
        userId: userId,
        category: category,
        createdAt: DateTime.now(),
      );

      // Add to Firebase
      final productId = await _firebaseService.createProduct(product);

      // Try to add to API as well
      try {
        await _apiService.createProduct(
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          url: url,
          category: category,
        );
      } catch (e) {
        debugPrint('API create product error: $e');
      }

      // Add to local list
      _products.insert(0, product.copyWith(id: productId));
      
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao adicionar produto';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Delete from Firebase
      await _firebaseService.deleteProduct(productId);

      // Try to delete from API as well
      try {
        await _apiService.deleteProduct(productId);
      } catch (e) {
        debugPrint('API delete product error: $e');
      }

      // Remove from local lists
      _products.removeWhere((p) => p.id == productId);
      _userProducts.removeWhere((p) => p.id == productId);
      
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao deletar produto';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Like/Unlike product
  Future<void> toggleLike(String productId, String userId) async {
    try {
      // Update Firebase
      await _firebaseService.likeProduct(productId, userId);

      // Try to update API as well
      try {
        await _apiService.likeProduct(productId);
      } catch (e) {
        debugPrint('API like product error: $e');
      }

      // Update local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final product = _products[index];
        final newLikedBy = List<String>.from(product.likedBy);
        
        if (newLikedBy.contains(userId)) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        _products[index] = product.copyWith(
          likedBy: newLikedBy,
          likes: newLikedBy.length,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erro ao curtir produto';
      notifyListeners();
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await loadProducts();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      List<Product> results = [];

      // Search in API
      try {
        final apiResults = await _apiService.searchProducts(query);
        results.addAll(apiResults);
      } catch (e) {
        debugPrint('API search error: $e');
      }

      // Search in Firebase
      try {
        final firebaseResults = await _firebaseService.searchProducts(query);
        
        // Merge results, avoiding duplicates
        for (var fbProduct in firebaseResults) {
          if (!results.any((p) => p.id == fbProduct.id)) {
            results.add(fbProduct);
          }
        }
      } catch (e) {
        debugPrint('Firebase search error: $e');
      }

      _products = results;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao buscar produtos';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    loadProducts(category: category);
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
