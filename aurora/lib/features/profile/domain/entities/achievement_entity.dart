class AchievementEntity {
  final String id;
  final String title;
  final String description;
  final String icon;
  final double currentProgress; // 0.0 to 1.0 or actual value
  final double targetValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.currentProgress,
    required this.targetValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progressPercentage => (currentProgress / targetValue).clamp(0.0, 1.0);
}
