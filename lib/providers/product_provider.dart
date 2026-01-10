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

  String _dedupeKey(Product p) {
    final u = p.url.trim();
    if (u.isNotEmpty) return 'url:$u';
    final name = p.name.trim().toLowerCase();
    final img = p.imageUrl.trim();
    return 'fallback:$name|$img|${p.price}';
  }

  // Load products from both API and Firebase
  Future<void> loadProducts({String? category}) async {
    _isLoading = true;
    _selectedCategory = category;
    notifyListeners();

    try {
      final Map<String, Product> merged = {};

      // Prefer Firebase as canonical (likes/user ops happen there)
      try {
        final firebaseProducts = await _firebaseService.getProducts(category: category);
        for (final fbProduct in firebaseProducts) {
          merged[_dedupeKey(fbProduct)] = fbProduct;
        }
      } catch (e) {
        debugPrint('Firebase load products error: $e');
      }

      // Best-effort: load from API (only if not already in Firebase)
      try {
        final apiProducts = await _apiService.getProducts(category: category);
        for (final apiProduct in apiProducts) {
          merged.putIfAbsent(_dedupeKey(apiProduct), () => apiProduct);
        }
      } catch (e) {
        debugPrint('API load products error: $e');
      }

      // Sort by creation date
      final allProducts = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
      String? apiId;
      try {
        final apiProduct = await _apiService.createProduct(
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          url: url,
          category: category,
        );
        apiId = apiProduct.apiId ?? apiProduct.id;
      } catch (e) {
        debugPrint('API create product error: $e');
      }

      if (apiId != null && apiId.isNotEmpty) {
        // Persist mapping to avoid calling API with a Firestore id later.
        try {
          await _firebaseService.updateProduct(productId, {'apiId': apiId});
        } catch (e) {
          debugPrint('Firebase update apiId error: $e');
        }
      }

      // Add to local list
      _products.insert(
        0,
        product.copyWith(
          id: productId,
          firebaseId: productId,
          apiId: apiId,
        ),
      );
      
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
      final local = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => _userProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: productId,
            name: '',
            description: '',
            price: 0,
            imageUrl: '',
            url: '',
            userId: '',
            createdAt: DateTime.now(),
          ),
        ),
      );

      // Delete from Firebase
      await _firebaseService.deleteProduct(productId);

      // Try to delete from API as well
      try {
        final apiId = local.apiId;
        if (apiId != null && apiId.isNotEmpty) {
          await _apiService.deleteProduct(apiId);
        }
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
      final index = _products.indexWhere((p) => p.id == productId);
      final product = index != -1 ? _products[index] : null;

      // If it exists in Firebase, that is the canonical like/unlike.
      if (product?.firebaseId != null) {
        await _firebaseService.likeProduct(product!.firebaseId!, userId);

        // Best-effort: update API using apiId if we have it.
        try {
          final apiId = product.apiId;
          if (apiId != null && apiId.isNotEmpty) {
            await _apiService.likeProduct(apiId);
          }
        } catch (e) {
          debugPrint('API like product error: $e');
        }
      } else {
        // API-only product
        try {
          await _apiService.likeProduct(productId);
        } catch (e) {
          debugPrint('API like product error: $e');
          rethrow;
        }
      }

      // Update local list
      if (index != -1) {
        final current = _products[index];
        final newLikedBy = List<String>.from(current.likedBy);
        
        if (newLikedBy.contains(userId)) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        _products[index] = current.copyWith(
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
      final Map<String, Product> merged = {};

      // Search in API
      try {
        final apiResults = await _apiService.searchProducts(query);
        for (final p in apiResults) {
          merged[_dedupeKey(p)] = p;
        }
      } catch (e) {
        debugPrint('API search error: $e');
      }

      // Search in Firebase
      try {
        final firebaseResults = await _firebaseService.searchProducts(query);
        for (final p in firebaseResults) {
          // Prefer Firebase result if duplicated
          merged[_dedupeKey(p)] = p;
        }
      } catch (e) {
        debugPrint('Firebase search error: $e');
      }

      _products = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
