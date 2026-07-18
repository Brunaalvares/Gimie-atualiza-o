import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance =
      PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _listeningRefresh = false;

  Future<void> initialize(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // No simulador iOS o token APNS costuma não existir; getToken falha.
      // Em device físico o fluxo segue normalmente.
      String? token;
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final apns = await _messaging.getAPNSToken();
          if (apns == null) {
            debugPrint(
              'PushNotificationService: APNS ainda indisponível '
              '(comum no Simulator). Token FCM será salvo no refresh.',
            );
          } else {
            token = await _messaging.getToken();
          }
        } else {
          token = await _messaging.getToken();
        }
      } catch (e) {
        debugPrint('PushNotificationService getToken skipped: $e');
      }

      if (token != null && token.isNotEmpty) {
        await _saveToken(userId, token);
      }

      if (!_listeningRefresh) {
        _listeningRefresh = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await _saveToken(userId, newToken);
        });
      }
    } catch (e) {
      debugPrint('PushNotificationService initialize error: $e');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
    }, SetOptions(merge: true));
  }
}
