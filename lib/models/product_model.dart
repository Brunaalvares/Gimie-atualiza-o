class Product {
  final String id;
  // IDs from different backends (optional). `id` is the in-app identifier.
  final String? apiId;
  final String? firebaseId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String url;
  final String userId;
  final String? category;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;

  Product({
    required this.id,
    this.apiId,
    this.firebaseId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.url,
    required this.userId,
    this.category,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString().trim().replaceAll(',', '.');
    return double.tryParse(s) ?? 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) {
      // Likely milliseconds since epoch.
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  // From JSON (API)
  factory Product.fromJson(Map<String, dynamic> json) {
    final apiId = json['id']?.toString() ?? json['_id']?.toString();
    return Product(
      id: apiId ?? '',
      apiId: apiId,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: _parseDouble(json['price']),
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      url: json['url'] ?? json['product_url'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      category: json['category'],
      createdAt: _parseDateTime(json['createdAt']),
      likes: (json['likes'] is num) ? (json['likes'] as num).toInt() : (int.tryParse('${json['likes']}') ?? 0),
      likedBy: _parseStringList(json['likedBy']),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'url': url,
      'userId': userId,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  // From Firestore
  factory Product.fromFirestore(Map<String, dynamic> data, String documentId) {
    DateTime createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt == null) {
      createdAt = DateTime.now();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else {
      try {
        createdAt = (rawCreatedAt as dynamic).toDate() as DateTime;
      } catch (_) {
        createdAt = DateTime.now();
      }
    }

    return Product(
      id: documentId,
      firebaseId: documentId,
      apiId: data['apiId']?.toString(),
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: _parseDouble(data['price']),
      imageUrl: data['imageUrl'] ?? '',
      url: data['url'] ?? '',
      userId: data['userId'] ?? '',
      category: data['category'],
      createdAt: createdAt,
      likes: (data['likes'] is num) ? (data['likes'] as num).toInt() : (int.tryParse('${data['likes']}') ?? 0),
      likedBy: _parseStringList(data['likedBy']),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'apiId': apiId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'url': url,
      'userId': userId,
      'category': category,
      'createdAt': createdAt,
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  // Formatted price
  String get formattedPrice {
    return 'R\$ ${price.toStringAsFixed(2)}';
  }

  // Copy with
  Product copyWith({
    String? id,
    String? apiId,
    String? firebaseId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? url,
    String? userId,
    String? category,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
  }) {
    return Product(
      id: id ?? this.id,
      apiId: apiId ?? this.apiId,
      firebaseId: firebaseId ?? this.firebaseId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}
