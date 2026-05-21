import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/trend_models.dart';
import 'firebase_service.dart';

/// Curadoria da aba **Trends** (Firestore `trend_boards` + Storage `trends/`).
///
/// **Admin:** no Console Firebase cria `admins/{seuUserId}` com `{ "active": true }`.
/// Só esses utilizadores podem editar pastas/cards (regras Firestore + Storage).
class TrendsService {
  TrendsService._();
  static final TrendsService instance = TrendsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseService _firebase = FirebaseService();

  bool? _adminCache;

  CollectionReference<Map<String, dynamic>> get _boards =>
      _db.collection('trend_boards');

  CollectionReference<Map<String, dynamic>> _moods(String boardId) =>
      _boards.doc(boardId).collection('mood_images');

  CollectionReference<Map<String, dynamic>> _items(String boardId) =>
      _boards.doc(boardId).collection('trend_products');

  void clearAdminCache() => _adminCache = null;

  Future<bool> isCurrentUserAdmin() async {
    if (_adminCache != null) return _adminCache!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _adminCache = false;
      return false;
    }
    try {
      final snap = await _db.collection('admins').doc(uid).get();
      _adminCache = snap.data()?['active'] == true;
      return _adminCache!;
    } catch (e) {
      debugPrint('Trends admin check: $e');
      _adminCache = false;
      return false;
    }
  }

  Stream<List<TrendBoard>> watchBoards() {
    return _boards.orderBy('sortOrder').snapshots().map(
          (s) => s.docs.map(TrendBoard.fromDoc).toList(),
        );
  }

  Future<TrendBoardContent> fetchBoardContent(String boardId) async {
    final boardSnap = await _boards.doc(boardId).get();
    if (!boardSnap.exists) {
      throw StateError('Pasta não encontrada');
    }
    final board = TrendBoard.fromDoc(boardSnap);
    final moodsSnap = await _moods(boardId).orderBy('sortOrder').get();
    final itemsSnap = await _items(boardId).orderBy('sortOrder').get();
    return TrendBoardContent(
      board: board,
      moods: moodsSnap.docs.map(TrendMoodImage.fromDoc).toList(),
      products: itemsSnap.docs.map(TrendManualProduct.fromDoc).toList(),
    );
  }

  Future<List<TrendBoardContent>> fetchAllTrendsContent() async {
    final snap = await _boards.orderBy('sortOrder').get();
    final out = <TrendBoardContent>[];
    for (final d in snap.docs) {
      out.add(await fetchBoardContent(d.id));
    }
    return out;
  }

  Future<int> _nextSortOrder(CollectionReference<Map<String, dynamic>> col) async {
    final q = await col.orderBy('sortOrder', descending: true).limit(1).get();
    if (q.docs.isEmpty) return 0;
    final v = q.docs.first.data()['sortOrder'];
    return (v is num ? v.toInt() : 0) + 1;
  }

  Future<String> createBoard({String title = 'Nova pasta'}) async {
    final ref = _boards.doc();
    final order = await _nextSortOrder(_boards);
    await ref.set({
      'title': title.trim().isEmpty ? 'Nova pasta' : title.trim(),
      'sortOrder': order,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateBoardMeta(String boardId, {String? title, int? sortOrder}) async {
    final map = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (title != null) map['title'] = title.trim();
    if (sortOrder != null) map['sortOrder'] = sortOrder;
    await _boards.doc(boardId).update(map);
  }

  Future<void> deleteBoard(String boardId) async {
    final moods = await _moods(boardId).get();
    for (final d in moods.docs) {
      await d.reference.delete();
    }
    final items = await _items(boardId).get();
    for (final d in items.docs) {
      await d.reference.delete();
    }
    await _boards.doc(boardId).delete();
  }

  /// Redimensiona para quadrado [size]×[size] px e exporta JPEG (aba Trends / mood).
  Uint8List prepareSquareJpeg(Uint8List raw, {int size = 1080}) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final sq = img.copyResizeCropSquare(decoded, size: size);
    return Uint8List.fromList(img.encodeJpg(sq, quality: 88));
  }

  Future<String> uploadMoodImage(String boardId, Uint8List jpegBytes) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'trends/$boardId/mood_$id.jpg';
    return _firebase.uploadImageFromBytes(jpegBytes, path);
  }

  Future<String> uploadProductCardImage(String boardId, Uint8List jpegBytes) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'trends/$boardId/product_$id.jpg';
    return _firebase.uploadImageFromBytes(jpegBytes, path);
  }

  Future<void> addMoodImage(String boardId, String downloadUrl) async {
    final ref = _moods(boardId).doc();
    final order = await _nextSortOrder(_moods(boardId));
    await ref.set({
      'imageUrl': downloadUrl,
      'sortOrder': order,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _boards.doc(boardId).update({'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteMoodImage(String boardId, String moodId) async {
    await _moods(boardId).doc(moodId).delete();
    await _boards.doc(boardId).update({'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> addOrUpdateProduct({
    required String boardId,
    String? productId,
    required String title,
    String? priceDisplay,
    required String imageUrl,
    required String linkUrl,
  }) async {
    final col = _items(boardId);
    final ref = productId != null ? col.doc(productId) : col.doc();

    final int sortOrder;
    if (productId != null) {
      final existing = await ref.get();
      sortOrder = (existing.data()?['sortOrder'] as num?)?.toInt() ?? 0;
    } else {
      sortOrder = await _nextSortOrder(col);
    }

    await ref.set({
      'title': title.trim(),
      'priceDisplay': (priceDisplay ?? '').trim(),
      'imageUrl': imageUrl.trim(),
      'linkUrl': linkUrl.trim(),
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _boards.doc(boardId).update({'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteProduct(String boardId, String productId) async {
    await _items(boardId).doc(productId).delete();
    await _boards.doc(boardId).update({'updatedAt': FieldValue.serverTimestamp()});
  }
}
