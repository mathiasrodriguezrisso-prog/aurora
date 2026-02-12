import 'profile_stats_entity.dart';

class GamificationStatsEntity extends ProfileStatsEntity {
  final int level;
  final int xp;
  final int xpNextLevel;
  final String title;
  final int successfulHarvests;
  final int daysActive;
  final int helpfulAnswers;

  const GamificationStatsEntity({
    required this.level,
    required this.xp,
    required this.xpNextLevel,
    required this.title,
    required super.followers,
    required super.following,
    required super.totalGrows,
    required super.totalPosts,
    required super.karmaTrend,
    required this.successfulHarvests,
    required this.daysActive,
    required this.helpfulAnswers,
  });
}
