import 'package:cloud_firestore/cloud_firestore.dart';

class TrendBoard {
  final String id;
  final String title;
  final int sortOrder;
  final DateTime? updatedAt;

  TrendBoard({
    required this.id,
    required this.title,
    required this.sortOrder,
    this.updatedAt,
  });

  factory TrendBoard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TrendBoard(
      id: doc.id,
      title: (d['title'] as String?)?.trim() ?? 'Trend',
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'sortOrder': sortOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class TrendMoodImage {
  final String id;
  final String imageUrl;
  final int sortOrder;

  TrendMoodImage({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
  });

  factory TrendMoodImage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TrendMoodImage(
      id: doc.id,
      imageUrl: (d['imageUrl'] as String?)?.trim() ?? '',
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class TrendManualProduct {
  final String id;
  final String title;
  final String? priceDisplay;
  final String imageUrl;
  final String linkUrl;
  final int sortOrder;

  TrendManualProduct({
    required this.id,
    required this.title,
    this.priceDisplay,
    required this.imageUrl,
    required this.linkUrl,
    required this.sortOrder,
  });

  factory TrendManualProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TrendManualProduct(
      id: doc.id,
      title: (d['title'] as String?)?.trim() ?? '',
      priceDisplay: (d['priceDisplay'] as String?)?.trim(),
      imageUrl: (d['imageUrl'] as String?)?.trim() ?? '',
      linkUrl: (d['linkUrl'] as String?)?.trim() ?? '',
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'priceDisplay': (priceDisplay ?? '').trim(),
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'sortOrder': sortOrder,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class TrendBoardContent {
  final TrendBoard board;
  final List<TrendMoodImage> moods;
  final List<TrendManualProduct> products;

  TrendBoardContent({
    required this.board,
    required this.moods,
    required this.products,
  });
}
