class UserNotification {
  final String id;
  final String recipientId;
  final String actorId;
  final String type;
  final String? productId;
  final String? productName;
  final String? actorName;
  final String? actorUsername;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.type,
    this.productId,
    this.productName,
    this.actorName,
    this.actorUsername,
    required this.createdAt,
  });

  factory UserNotification.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    DateTime created;
    final raw = data['createdAt'];
    if (raw == null) {
      created = DateTime.now();
    } else {
      try {
        created = (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        created = DateTime.tryParse(raw.toString()) ?? DateTime.now();
      }
    }

    return UserNotification(
      id: documentId,
      recipientId: data['recipientId']?.toString() ?? '',
      actorId: data['actorId']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      productId: data['productId']?.toString(),
      productName: data['productName']?.toString(),
      actorName: data['actorName']?.toString(),
      actorUsername: data['actorUsername']?.toString(),
      createdAt: created,
    );
  }

  String get displayTitle {
    switch (type) {
      case 'follow':
        return 'Novo seguidor';
      case 'like':
        return 'Curtida no seu produto';
      default:
        return 'Atividade';
    }
  }

  String get displaySubtitle {
    final handle = (actorUsername != null && actorUsername!.trim().isNotEmpty)
        ? '@${actorUsername!.trim()}'
        : (actorName != null && actorName!.trim().isNotEmpty)
            ? actorName!.trim()
            : 'Usuário';
    if (type == 'follow') {
      return '$handle começou a seguir você';
    }
    if (type == 'like') {
      final product = (productName != null && productName!.trim().isNotEmpty)
          ? '“${productName!.trim()}”'
          : 'um dos seus produtos';
      return '$handle curtiu $product';
    }
    return handle;
  }
}
