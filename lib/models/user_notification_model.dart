class UserNotification {
  final String id;
  final String recipientId;
  final String actorId;
  final String type;
  final String? productId;
  final String? productName;
  final String? actorName;
  final String? actorUsername;
  final String? badgeId;
  final String? badgeName;
  final String? metricName;
  final String? folderName;
  final bool isRead;
  final DateTime? readAt;
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
    this.badgeId,
    this.badgeName,
    this.metricName,
    this.folderName,
    this.isRead = false,
    this.readAt,
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
      badgeId: data['badgeId']?.toString(),
      badgeName: data['badgeName']?.toString(),
      metricName: data['metricName']?.toString(),
      folderName: data['folderName']?.toString(),
      isRead: data['isRead'] == true,
      readAt: _parseDate(data['readAt']),
      createdAt: created,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return (raw as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse(raw.toString());
    }
  }

  String get displayTitle {
    switch (type) {
      case 'follow':
        return 'Novo seguidor';
      case 'like':
        return 'Curtida no seu produto';
      case 'badge_earned':
        return 'Novo badge conquistado';
      case 'metric_event':
        return 'Nova atividade';
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
    if (type == 'badge_earned') {
      final value = (badgeName != null && badgeName!.trim().isNotEmpty)
          ? badgeName!.trim()
          : 'um novo badge';
      return 'Você conquistou: $value';
    }
    if (type == 'metric_event') {
      final metric = metricName?.trim();
      if (metric != null && metric.isNotEmpty) {
        return '$handle registrou atividade de $metric';
      }
    }
    return handle;
  }
}
