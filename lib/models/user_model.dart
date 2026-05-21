class UserModel {
  final String id;
  final String email;
  final String name;
  final String username;
  final String? photoUrl;
  final String? bio;
  final DateTime? birthDate;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final List<String> followingIds;
  final List<String> emptyFolders;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    this.photoUrl,
    this.bio,
    this.birthDate,
    required this.createdAt,
    this.lastLogin,
    this.followingIds = const [],
    this.emptyFolders = const [],
  });

  // From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      bio: json['bio']?.toString(),
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      followingIds: (json['followingIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          (json['following'] as List<dynamic>?)
                  ?.map((id) => id.toString())
                  .toList() ??
          const [],
      emptyFolders: (json['emptyFolders'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
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
      'bio': bio,
      'birthDate': birthDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'followingIds': followingIds,
      'emptyFolders': emptyFolders,
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
      bio: data['bio']?.toString(),
      birthDate: _parseBirthDateFromFirestore(data['birthDate']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as dynamic).toDate()
          : null,
      followingIds: (data['followingIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          (data['following'] as List<dynamic>?)
                  ?.map((id) => id.toString())
                  .toList() ??
          const [],
      emptyFolders: (data['emptyFolders'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'birthDate': birthDate,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'followingIds': followingIds,
      'emptyFolders': emptyFolders,
    };
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? photoUrl,
    String? bio,
    DateTime? birthDate,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? followingIds,
    List<String>? emptyFolders,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      followingIds: followingIds ?? this.followingIds,
      emptyFolders: emptyFolders ?? this.emptyFolders,
    );
  }
}

DateTime? _parseBirthDateFromFirestore(dynamic value) {
  if (value == null) return null;
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {
    return DateTime.tryParse(value.toString());
  }
}
