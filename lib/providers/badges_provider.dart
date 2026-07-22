import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/badge_model.dart';
import '../services/badges_service.dart';

class BadgesProvider extends ChangeNotifier {
  final BadgesService _service = BadgesService.instance;

  List<BadgeProgress> _badges = const [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<BadgeProgress>>? _subscription;
  String? _currentUserId;

  List<BadgeProgress> get badges => _badges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> bindUser(String userId) async {
    debugPrint('BADGES_PROVIDER: bindUser called for: $userId');
    
    if (_currentUserId == userId && _subscription != null) {
      debugPrint('BADGES_PROVIDER: Already bound to this user, skipping');
      return;
    }
    
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _subscription?.cancel();
    
    debugPrint('BADGES_PROVIDER: Starting to watch badges for: $userId');
    
    _subscription = _service.watchBadges(userId).listen(
      (items) {
        debugPrint('BADGES_PROVIDER: Received ${items.length} badges');
        _badges = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('BADGES_PROVIDER: Error watching badges: $error');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refresh(String userId) async {
    try {
      await _service.evaluateAndSync(userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
