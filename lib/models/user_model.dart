class UserModel {
  final String id;
  final String email;
  final String name;
  final String username;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    this.photoUrl,
    required this.createdAt,
    this.lastLogin,
  });

  static DateTime _parseDateTime(dynamic value, {required DateTime fallback}) {
    if (value == null) return fallback;
    if (value is DateTime) return value;
    if (value is int) {
      // Likely milliseconds since epoch.
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final s = value.toString().trim();
    return DateTime.tryParse(s) ?? fallback;
  }

  // From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? json['uid'] ?? '').toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      createdAt: _parseDateTime(json['createdAt'], fallback: DateTime.now()),
      lastLogin: json['lastLogin'] != null
          ? _parseDateTime(json['lastLogin'], fallback: DateTime.now())
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'username': username,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // From Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as dynamic).toDate()
          : null,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'username': username,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
