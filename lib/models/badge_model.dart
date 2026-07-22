class BadgeDefinition {
  final String id;
  final String title;
  final String description;
  final String category;
  final String tier;
  final int target;
  final bool isComingSoon;

  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.target,
    this.isComingSoon = false,
  });
}

class BadgeProgress {
  final String badgeId;
  final String title;
  final String description;
  final String category;
  final String tier;
  final int target;
  final int current;
  final bool earned;
  final DateTime? earnedAt;
  final DateTime? updatedAt;
  final String? progressLabel;
  final bool isComingSoon;

  const BadgeProgress({
    required this.badgeId,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.target,
    required this.current,
    required this.earned,
    this.earnedAt,
    this.updatedAt,
    this.progressLabel,
    this.isComingSoon = false,
  });

  factory BadgeProgress.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        try {
          return DateTime.tryParse(value.toString());
        } catch (_) {
          return null;
        }
      }
    }

    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      try {
        return int.tryParse(value.toString()) ?? defaultValue;
      } catch (_) {
        return defaultValue;
      }
    }

    return BadgeProgress(
      badgeId: data['badgeId']?.toString() ?? id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      tier: data['tier']?.toString() ?? '',
      target: parseInt(data['target'], 0),
      current: parseInt(data['current'], 0),
      earned: data['earned'] == true,
      earnedAt: parseDate(data['earnedAt']),
      updatedAt: parseDate(data['updatedAt']),
      progressLabel: data['progressLabel']?.toString(),
      isComingSoon: data['isComingSoon'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'badgeId': badgeId,
      'title': title,
      'description': description,
      'category': category,
      'tier': tier,
      'target': target,
      'current': current,
      'earned': earned,
      'earnedAt': earnedAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'progressLabel': progressLabel,
      'isComingSoon': isComingSoon,
    };
  }
}
