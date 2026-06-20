enum ChallengeType { steps, workout, nutrition, habit, custom }
enum ChallengeStatus { upcoming, active, completed }
enum BadgeType { bronze, silver, gold, platinum }

class ChallengeBadge {
  final String id;
  final String name;
  final String emoji;
  final BadgeType type;
  final String description;

  ChallengeBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.description,
  });
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final int rank;
  final double progress;
  final int score;
  final bool isMe;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.rank,
    required this.progress,
    required this.score,
    required this.isMe,
  });
}

class ChallengeReward {
  final String title;
  final String description;
  final String emoji;
  final int requiredRank;

  ChallengeReward({
    required this.title,
    required this.description,
    required this.emoji,
    required this.requiredRank,
  });
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final String unit;
  final double myProgress;
  final int participantCount;
  final List<LeaderboardEntry> leaderboard;
  final List<ChallengeReward> rewards;
  final List<ChallengeBadge> badges;
  final bool isJoined;
  final String coachName;
  final String emoji;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    required this.unit,
    required this.myProgress,
    required this.participantCount,
    required this.leaderboard,
    required this.rewards,
    required this.badges,
    required this.isJoined,
    required this.coachName,
    required this.emoji,
  });

  int get daysLeft => endDate.difference(DateTime.now()).inDays;
  double get progressPercent => (myProgress / targetValue).clamp(0.0, 1.0);
}
