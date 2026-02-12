/// 📁 lib/features/profile/domain/entities/profile_stats_entity.dart

class ProfileStatsEntity {
  final int followers;
  final int following;
  final int totalGrows;
  final int totalPosts;
  final double karmaTrend;

  const ProfileStatsEntity({
    required this.followers,
    required this.following,
    required this.totalGrows,
    required this.totalPosts,
    required this.karmaTrend,
  });
}
