import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class SharedFolderProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _owner;
  List<Product> _products = const [];
  String? _loadedKey;
  Timer? _debounce;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get owner => _owner;
  List<Product> get products => _products;

  void loadDebounced({
    required String userId,
    required String folderName,
    Duration delay = const Duration(milliseconds: 280),
  }) {
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      unawaited(load(userId: userId, folderName: folderName));
    });
  }

  Future<void> load({
    required String userId,
    required String folderName,
  }) async {
    final key = '${userId.trim()}|${folderName.trim().toLowerCase()}';
    if (_isLoading && _loadedKey == key) return;

    _isLoading = true;
    _errorMessage = null;
    _loadedKey = key;
    notifyListeners();

    try {
      final owner = await _firebaseService.getUserDocumentReadOnly(userId);
      if (owner == null) {
        _owner = null;
        _products = const [];
        _errorMessage = 'Não foi possível carregar esta pasta';
        return;
      }

      final all = await _firebaseService.getUserProducts(userId);
      final folderLower = folderName.trim().toLowerCase();
      final filtered = all
          .where(
            (p) => (p.category ?? '').trim().toLowerCase() == folderLower,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _owner = owner;
      _products = filtered;
      _errorMessage = null;
    } catch (_) {
      _owner = null;
      _products = const [];
      _errorMessage = 'Não foi possível carregar esta pasta';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
