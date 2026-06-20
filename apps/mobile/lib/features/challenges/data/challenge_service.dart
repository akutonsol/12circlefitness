import 'models/challenge_model.dart';

class ChallengeService {
  List<Challenge> getSampleChallenges() {
    final now = DateTime.now();
    return [
      Challenge(
        id: '1',
        title: '30-Day Step Challenge',
        description: 'Walk 10,000 steps every day for 30 days. Build the habit of daily movement and compete with your circle!',
        type: ChallengeType.steps,
        status: ChallengeStatus.active,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        targetValue: 300000,
        unit: 'steps',
        myProgress: 187500,
        participantCount: 0,
        isJoined: false,
        coachName: 'Coach Julia',
        emoji: '👟',
        leaderboard: [
          LeaderboardEntry(userId: 'u1', userName: 'Monica W', rank: 1, progress: 0.95, score: 285000, isMe: false),
          LeaderboardEntry(userId: 'u2', userName: 'Jessica T', rank: 2, progress: 0.88, score: 264000, isMe: false),
          LeaderboardEntry(userId: 'u3', userName: 'You', rank: 3, progress: 0.625, score: 187500, isMe: true),
          LeaderboardEntry(userId: 'u4', userName: 'Amanda R', rank: 4, progress: 0.60, score: 180000, isMe: false),
          LeaderboardEntry(userId: 'u5', userName: 'Rachel M', rank: 5, progress: 0.55, score: 165000, isMe: false),
          LeaderboardEntry(userId: 'u6', userName: 'Tanya B', rank: 6, progress: 0.48, score: 144000, isMe: false),
        ],
        rewards: [
          ChallengeReward(title: 'Champion', description: '1 month free premium', emoji: '🏆', requiredRank: 1),
          ChallengeReward(title: 'Runner Up', description: '2 weeks free premium', emoji: '🥈', requiredRank: 2),
          ChallengeReward(title: 'Bronze', description: '1 week free premium', emoji: '🥉', requiredRank: 3),
        ],
        badges: [
          ChallengeBadge(id: 'b1', name: 'First Steps', emoji: '👣', type: BadgeType.bronze, description: 'Complete 3 days'),
          ChallengeBadge(id: 'b2', name: 'On the Move', emoji: '🚶', type: BadgeType.silver, description: 'Complete 10 days'),
          ChallengeBadge(id: 'b3', name: 'Step Master', emoji: '⭐', type: BadgeType.gold, description: 'Complete all 30 days'),
        ],
      ),
      Challenge(
        id: '2',
        title: '21-Day Workout Streak',
        description: 'Complete at least 3 workouts per week for 21 days. Build an unbreakable fitness habit!',
        type: ChallengeType.workout,
        status: ChallengeStatus.active,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 16)),
        targetValue: 9,
        unit: 'workouts',
        myProgress: 4,
        participantCount: 0,
        isJoined: false,
        coachName: 'Coach Julia',
        emoji: '💪',
        leaderboard: [
          LeaderboardEntry(userId: 'u1', userName: 'Julia L', rank: 1, progress: 0.78, score: 7, isMe: false),
          LeaderboardEntry(userId: 'u2', userName: 'You', rank: 2, progress: 0.44, score: 4, isMe: true),
          LeaderboardEntry(userId: 'u3', userName: 'Michelle K', rank: 3, progress: 0.33, score: 3, isMe: false),
          LeaderboardEntry(userId: 'u4', userName: 'Lisa P', rank: 4, progress: 0.22, score: 2, isMe: false),
        ],
        rewards: [
          ChallengeReward(title: 'Workout Queen', description: 'Custom workout plan', emoji: '👑', requiredRank: 1),
          ChallengeReward(title: 'Consistent', description: 'Free coaching session', emoji: '🌟', requiredRank: 2),
        ],
        badges: [
          ChallengeBadge(id: 'b4', name: 'Getting Started', emoji: '🔥', type: BadgeType.bronze, description: 'Complete 3 workouts'),
          ChallengeBadge(id: 'b5', name: 'Halfway There', emoji: '💪', type: BadgeType.silver, description: 'Complete 5 workouts'),
          ChallengeBadge(id: 'b6', name: 'Unstoppable', emoji: '🏆', type: BadgeType.gold, description: 'Complete all 9 workouts'),
        ],
      ),
      Challenge(
        id: '3',
        title: 'Protein Challenge',
        description: 'Hit your daily protein goal for 14 consecutive days. Fuel your transformation!',
        type: ChallengeType.nutrition,
        status: ChallengeStatus.upcoming,
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 17)),
        targetValue: 14,
        unit: 'days',
        myProgress: 0,
        participantCount: 0,
        isJoined: false,
        coachName: 'Nutritionist Kim',
        emoji: '🥩',
        leaderboard: [],
        rewards: [
          ChallengeReward(title: 'Protein Queen', description: 'Custom meal plan', emoji: '🥇', requiredRank: 1),
        ],
        badges: [
          ChallengeBadge(id: 'b7', name: 'Protein Starter', emoji: '🥚', type: BadgeType.bronze, description: 'Complete 3 days'),
          ChallengeBadge(id: 'b8', name: 'Macro Master', emoji: '💊', type: BadgeType.gold, description: 'Complete all 14 days'),
        ],
      ),
      Challenge(
        id: '4',
        title: 'Summer Transformation',
        description: 'Complete the 8-week full body transformation challenge. Track workouts, nutrition and check-ins.',
        type: ChallengeType.custom,
        status: ChallengeStatus.completed,
        startDate: now.subtract(const Duration(days: 60)),
        endDate: now.subtract(const Duration(days: 4)),
        targetValue: 100,
        unit: 'points',
        myProgress: 87,
        participantCount: 0,
        isJoined: false,
        coachName: 'Coach Julia',
        emoji: '☀️',
        leaderboard: [
          LeaderboardEntry(userId: 'u1', userName: 'Monica W', rank: 1, progress: 1.0, score: 100, isMe: false),
          LeaderboardEntry(userId: 'u2', userName: 'You', rank: 4, progress: 0.87, score: 87, isMe: true),
        ],
        rewards: [
          ChallengeReward(title: 'Transformation Champion', description: '3 months free premium', emoji: '🏆', requiredRank: 1),
        ],
        badges: [
          ChallengeBadge(id: 'b9', name: 'Transformer', emoji: '✨', type: BadgeType.platinum, description: 'Complete the challenge'),
        ],
      ),
    ];
  }
}
