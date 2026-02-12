import '../../domain/entities/gamification_stats_entity.dart';

class GamificationStatsModel extends GamificationStatsEntity {
  final int level;
  final int xp;
  final int xpNextLevel;
  final String title;
  final int successfulHarvests;
  final int daysActive;
  final int helpfulAnswers;

  const GamificationStatsModel({
    this.level = 1,
    this.xp = 0,
    this.xpNextLevel = 100,
    this.title = 'Novice',
    required super.followers,
    required super.following,
    required super.totalGrows,
    required super.totalPosts,
    required super.karmaTrend,
    this.successfulHarvests = 0,
    this.daysActive = 0,
    this.helpfulAnswers = 0,
  });

  factory GamificationStatsModel.fromJson(Map<String, dynamic> json) {
    return GamificationStatsModel(
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      xpNextLevel: (json['xp_next_level'] as num?)?.toInt() ?? 100,
      title: json['title'] as String? ?? 'Novice',
      followers: (json['followers_count'] as num?)?.toInt() ?? 0,
      following: (json['following_count'] as num?)?.toInt() ?? 0,
      totalGrows: (json['total_grows'] as num?)?.toInt() ?? 0,
      totalPosts: (json['total_posts'] as num?)?.toInt() ?? 0,
      karmaTrend: (json['karma_trend'] as num?)?.toDouble() ?? 0.0,
      successfulHarvests: (json['successful_harvests'] as num?)?.toInt() ?? 0,
      daysActive: (json['days_active'] as num?)?.toInt() ?? 0,
      helpfulAnswers: (json['helpful_answers'] as num?)?.toInt() ?? 0,
    );
  }
}
