class MetricsSummary {
  final int searchCount;
  final int profileVisits;
  final int productVisits;
  final int folderViews;
  final int trendViews;
  final int shopNowClicks;
  final int likesGiven;
  final int followsCount;
  final int savedProductsCount;
  final int foldersCreatedCount;
  final int streakDays;
  final int maxStreakDays;
  final String? lastActiveDate;

  const MetricsSummary({
    this.searchCount = 0,
    this.profileVisits = 0,
    this.productVisits = 0,
    this.folderViews = 0,
    this.trendViews = 0,
    this.shopNowClicks = 0,
    this.likesGiven = 0,
    this.followsCount = 0,
    this.savedProductsCount = 0,
    this.foldersCreatedCount = 0,
    this.streakDays = 0,
    this.maxStreakDays = 0,
    this.lastActiveDate,
  });

  factory MetricsSummary.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const MetricsSummary();
    int parseInt(String key) => (data[key] as num?)?.toInt() ?? 0;
    return MetricsSummary(
      searchCount: parseInt('searchCount'),
      profileVisits: parseInt('profileVisits'),
      productVisits: parseInt('productVisits'),
      folderViews: parseInt('folderViews'),
      trendViews: parseInt('trendViews'),
      shopNowClicks: parseInt('shopNowClicks'),
      likesGiven: parseInt('likesGiven'),
      followsCount: parseInt('followsCount'),
      savedProductsCount: parseInt('savedProductsCount'),
      foldersCreatedCount: parseInt('foldersCreatedCount'),
      streakDays: parseInt('streakDays'),
      maxStreakDays: parseInt('maxStreakDays'),
      lastActiveDate: data['lastActiveDate']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'searchCount': searchCount,
      'profileVisits': profileVisits,
      'productVisits': productVisits,
      'folderViews': folderViews,
      'trendViews': trendViews,
      'shopNowClicks': shopNowClicks,
      'likesGiven': likesGiven,
      'followsCount': followsCount,
      'savedProductsCount': savedProductsCount,
      'foldersCreatedCount': foldersCreatedCount,
      'streakDays': streakDays,
      'maxStreakDays': maxStreakDays,
      'lastActiveDate': lastActiveDate,
      'updatedAt': DateTime.now(),
    };
  }
}
