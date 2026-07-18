import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'badges_service.dart';
import 'firebase_service.dart';

class MetricsService {
  MetricsService._internal();
  static final MetricsService instance = MetricsService._internal();

  final FirebaseService _firebase = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> trackSearch({
    required String userId,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    await _firebase.incrementUserMetric(userId: userId, field: 'searchCount');
    await _firebase.createInternalNotification(
      recipientId: userId,
      actorId: userId,
      type: 'metric_event',
      metricName: 'pesquisa',
    );
    await BadgesService.instance.evaluateAndSync(userId);
  }

  Future<void> trackProfileVisit({
    required String ownerId,
    required String viewerId,
  }) async {
    await _firebase.recordProfileVisit(ownerId: ownerId, viewerId: viewerId);
    await BadgesService.instance.evaluateAndSync(ownerId);
  }

  Future<void> trackFolderView({
    required String ownerId,
    required String viewerId,
    required String folderName,
    String source = 'app',
  }) async {
    await _firebase.recordFolderView(
      ownerId: ownerId,
      viewerId: viewerId,
      folderName: folderName,
      source: source,
    );
    await BadgesService.instance.evaluateAndSync(ownerId);
  }

  Future<void> trackProductVisit({
    required String ownerId,
    required String viewerId,
    required String productId,
    String? productName,
  }) async {
    await _firebase.recordProductVisit(
      ownerId: ownerId,
      viewerId: viewerId,
      productId: productId,
      productName: productName,
    );
    await BadgesService.instance.evaluateAndSync(ownerId);
  }

  Future<void> trackShopNowClick({
    required String ownerId,
    required String viewerId,
    required String productId,
    String? productName,
  }) async {
    await _firebase.recordShopNowClick(
      ownerId: ownerId,
      viewerId: viewerId,
      productId: productId,
      productName: productName,
    );
    await BadgesService.instance.evaluateAndSync(ownerId);
  }

  Future<void> trackTrendVisit({required String userId}) async {
    await _firebase.recordTrendVisit(userId);
    await BadgesService.instance.evaluateAndSync(userId);
  }

  Future<void> trackFollow({required String userId}) async {
    await _firebase.incrementUserMetric(userId: userId, field: 'followsCount');
    await _firebase.createInternalNotification(
      recipientId: userId,
      actorId: userId,
      type: 'metric_event',
      metricName: 'novo perfil seguido',
    );
    await BadgesService.instance.evaluateAndSync(userId);
  }

  Future<void> trackLikeGiven({required String userId}) async {
    await _firebase.incrementUserMetric(userId: userId, field: 'likesGiven');
    await _firebase.createInternalNotification(
      recipientId: userId,
      actorId: userId,
      type: 'metric_event',
      metricName: 'curtida enviada',
    );
    await BadgesService.instance.evaluateAndSync(userId);
  }

  Future<void> touchDailyStreak({required String userId}) async {
    await _firebase.touchDailyStreak(userId);
    await BadgesService.instance.evaluateAndSync(userId);
  }

  Future<void> syncSavedProductsCount({required String userId}) async {
    // Só o próprio utilizador pode escrever em metrics/summary (regras).
    if (_firebase.currentUser?.uid != userId) return;
    try {
      final products = await _firebase.getUserProducts(userId);
      final folders = products
          .map((p) => (p.category ?? '').trim())
          .where((c) => c.isNotEmpty)
          .toSet()
          .length;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('metrics')
          .doc('summary')
          .set({
        'savedProductsCount': products.length,
        'foldersCreatedCount': folders,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync saved products count error: $e');
    }
    await BadgesService.instance.evaluateAndSync(userId);
  }
}
