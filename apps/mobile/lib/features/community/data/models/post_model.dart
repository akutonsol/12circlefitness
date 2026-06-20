enum PostType { text, photo, progress, workout, achievement }
enum ReactionType { like, love, fire, clap, strong }

class PostReaction {
  final String userId;
  final ReactionType type;

  PostReaction({required this.userId, required this.type});
}

class PostComment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final int likes;
  bool isLiked;

  PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.likes,
    this.isLiked = false,
  });
}

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String? userAvatar;
  final String content;
  final PostType type;
  final List<String> imageUrls;
  final List<PostReaction> reactions;
  final List<PostComment> comments;
  final DateTime createdAt;
  final String? groupId;
  final String? groupName;
  bool isLiked;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.userAvatar,
    required this.content,
    required this.type,
    required this.imageUrls,
    required this.reactions,
    required this.comments,
    required this.createdAt,
    this.groupId,
    this.groupName,
    this.isLiked = false,
  });

  int get likeCount => reactions.where((r) => r.type == ReactionType.like).length;
  int get fireCount => reactions.where((r) => r.type == ReactionType.fire).length;
  int get loveCount => reactions.where((r) => r.type == ReactionType.love).length;
}

class CommunityGroup {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int memberCount;
  final bool isJoined;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.memberCount,
    required this.isJoined,
  });
}
