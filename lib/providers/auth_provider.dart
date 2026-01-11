import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();
  StreamSubscription? _authSub;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _authSub?.cancel();
    _authSub = _firebaseService.authStateChanges.listen((user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final user = await _firebaseService.getUserDocument(userId);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados do usuário';
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try API login first
      try {
        final apiResponse = await _apiService.login(email, password);
        if (apiResponse['token'] != null) {
          _apiService.setAuthToken(apiResponse['token']);
        }
      } catch (e) {
        debugPrint('API login error: $e');
      }

      // Firebase login
      final credential = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Erro ao fazer login';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try API registration first
      try {
        final apiResponse = await _apiService.register(
          email: email,
          password: password,
          name: name,
          username: username,
        );
        if (apiResponse['token'] != null) {
          _apiService.setAuthToken(apiResponse['token']);
        }
      } catch (e) {
        debugPrint('API registration error: $e');
      }

      // Firebase registration
      final credential = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          username: username,
          createdAt: DateTime.now(),
        );

        await _firebaseService.createUserDocument(newUser);
        _currentUser = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Erro ao criar conta';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _apiService.clearAuthToken();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao fazer logout';
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao enviar email de recuperação';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (username != null) updates['username'] = username;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firebaseService.updateUserDocument(_currentUser!.id, updates);

      // Try to update in API as well
      try {
        await _apiService.updateUserProfile(
          userId: _currentUser!.id,
          name: name,
          username: username,
          photoUrl: photoUrl,
        );
      } catch (e) {
        debugPrint('API update profile error: $e');
      }

      _currentUser = _currentUser!.copyWith(
        name: name,
        username: username,
        photoUrl: photoUrl,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao atualizar perfil';
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Usuário não encontrado';
    } else if (error.contains('wrong-password')) {
      return 'Senha incorreta';
    } else if (error.contains('email-already-in-use')) {
      return 'Email já está em uso';
    } else if (error.contains('invalid-email')) {
      return 'Email inválido';
    } else if (error.contains('weak-password')) {
      return 'Senha muito fraca';
    } else if (error.contains('network-request-failed')) {
      return 'Erro de conexão';
    }
    return 'Erro desconhecido';
  }
}
