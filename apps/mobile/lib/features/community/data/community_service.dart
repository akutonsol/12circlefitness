import 'models/post_model.dart';

class CommunityService {
  List<CommunityPost> getSamplePosts() {
    final now = DateTime.now();
    return [
      CommunityPost(
        id: '1',
        userId: 'user1',
        userName: 'Julia Logan',
        userRole: 'Client',
        content: 'Just completed Week 8 of my transformation journey! Down 12 lbs and feeling absolutely amazing. The consistency is KEY ladies! 💪🔥 Who else is crushing their goals this week?',
        type: PostType.progress,
        imageUrls: [],
        isLiked: false,
        reactions: [
          PostReaction(userId: 'u1', type: ReactionType.fire),
          PostReaction(userId: 'u2', type: ReactionType.fire),
          PostReaction(userId: 'u3', type: ReactionType.love),
          PostReaction(userId: 'u4', type: ReactionType.like),
          PostReaction(userId: 'u5', type: ReactionType.clap),
          PostReaction(userId: 'u6', type: ReactionType.fire),
        ],
        comments: [
          PostComment(id: 'c1', userId: 'u2', userName: 'Coach Julia', content: 'This is incredible progress! So proud of you! 🙌', createdAt: now.subtract(const Duration(hours: 1)), likes: 5, isLiked: false),
          PostComment(id: 'c2', userId: 'u3', userName: 'Michelle K', content: 'You are such an inspiration! Keep going girl! ❤️', createdAt: now.subtract(const Duration(minutes: 45)), likes: 3, isLiked: false),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
        groupId: '1',
        groupName: 'Transformation Squad',
      ),
      CommunityPost(
        id: '2',
        userId: 'coach1',
        userName: 'Coach Julia',
        userRole: 'Coach',
        content: '🎯 WORKOUT TIP OF THE DAY:\n\nFor maximum glute activation during hip thrusts:\n✅ Drive through your HEELS not your toes\n✅ Full hip extension at the top\n✅ 2 second squeeze at peak\n✅ Control the negative\n\nTag someone who needs to hear this! 👇',
        type: PostType.text,
        imageUrls: [],
        isLiked: true,
        reactions: [
          PostReaction(userId: 'u1', type: ReactionType.like),
          PostReaction(userId: 'u2', type: ReactionType.fire),
          PostReaction(userId: 'u3', type: ReactionType.clap),
          PostReaction(userId: 'u4', type: ReactionType.like),
          PostReaction(userId: 'u5', type: ReactionType.strong),
          PostReaction(userId: 'u6', type: ReactionType.fire),
          PostReaction(userId: 'u7', type: ReactionType.like),
          PostReaction(userId: 'u8', type: ReactionType.clap),
        ],
        comments: [
          PostComment(id: 'c3', userId: 'u1', userName: 'Jessica T', content: 'Game changer tip! My glutes have never been more sore 😅', createdAt: now.subtract(const Duration(hours: 3)), likes: 8, isLiked: true),
          PostComment(id: 'c4', userId: 'u4', userName: 'Amanda R', content: 'Tagging my workout partner @Lisa! You need this!', createdAt: now.subtract(const Duration(hours: 2, minutes: 30)), likes: 2, isLiked: false),
        ],
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      CommunityPost(
        id: '3',
        userId: 'user3',
        userName: 'Monica Williams',
        userRole: 'Client',
        content: 'New PR alert! 🏆 Just hit 80kg on hip thrusts for the first time! 6 months ago I could barely do bodyweight. This community and Coach Julia have changed my life. Never give up on yourself! 💜',
        type: PostType.achievement,
        imageUrls: [],
        isLiked: false,
        reactions: [
          PostReaction(userId: 'u1', type: ReactionType.fire),
          PostReaction(userId: 'u2', type: ReactionType.love),
          PostReaction(userId: 'u3', type: ReactionType.clap),
          PostReaction(userId: 'u4', type: ReactionType.strong),
          PostReaction(userId: 'u5', type: ReactionType.fire),
          PostReaction(userId: 'u6', type: ReactionType.love),
          PostReaction(userId: 'u7', type: ReactionType.clap),
          PostReaction(userId: 'u8', type: ReactionType.fire),
          PostReaction(userId: 'u9', type: ReactionType.like),
          PostReaction(userId: 'u10', type: ReactionType.strong),
        ],
        comments: [
          PostComment(id: 'c5', userId: 'coach1', userName: 'Coach Julia', content: 'YESSS MONICA!! This is what we work for! 🔥🔥🔥', createdAt: now.subtract(const Duration(minutes: 30)), likes: 12, isLiked: false),
        ],
        createdAt: now.subtract(const Duration(hours: 6)),
        groupId: '1',
        groupName: 'Transformation Squad',
      ),
      CommunityPost(
        id: '4',
        userId: 'user4',
        userName: 'Tanya Brown',
        userRole: 'Client',
        content: 'Meal prep Sunday done! 🥗 Prepped all my lunches for the week. Chicken breast, brown rice, and roasted veggies. Staying consistent with nutrition is half the battle. What are you all prepping this week?',
        type: PostType.photo,
        imageUrls: [],
        isLiked: false,
        reactions: [
          PostReaction(userId: 'u1', type: ReactionType.like),
          PostReaction(userId: 'u2', type: ReactionType.clap),
          PostReaction(userId: 'u3', type: ReactionType.love),
          PostReaction(userId: 'u4', type: ReactionType.like),
        ],
        comments: [
          PostComment(id: 'c6', userId: 'u5', userName: 'Rachel M', content: 'Goals! I need to get better at meal prep 🙏', createdAt: now.subtract(const Duration(hours: 1)), likes: 1, isLiked: false),
        ],
        createdAt: now.subtract(const Duration(hours: 8)),
        groupId: '2',
        groupName: 'Nutrition Warriors',
      ),
    ];
  }

  List<CommunityGroup> getSampleGroups() {
    return [
      CommunityGroup(id: '1', name: 'Transformation Squad', description: 'Share your progress and inspire others on their transformation journey', emoji: '💪', memberCount: 248, isJoined: true),
      CommunityGroup(id: '2', name: 'Nutrition Warriors', description: 'Meal prep tips, recipes, and nutrition accountability', emoji: '🥗', memberCount: 183, isJoined: true),
      CommunityGroup(id: '3', name: 'Mindset & Wellness', description: 'Mental health, meditation, and holistic wellness discussions', emoji: '🧘', memberCount: 142, isJoined: false),
      CommunityGroup(id: '4', name: 'Beginners Circle', description: 'A safe space for those just starting their fitness journey', emoji: '🌱', memberCount: 321, isJoined: false),
      CommunityGroup(id: '5', name: 'Advanced Athletes', description: 'For experienced members pushing their limits', emoji: '🏆', memberCount: 97, isJoined: false),
    ];
  }
}
