import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/post_model.dart';

class ReactionBar extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const ReactionBar({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final totalReactions = post.reactions.length;
    final commentCount = post.comments.length;

    return Column(
      children: [
        if (totalReactions > 0 || commentCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (totalReactions > 0)
                  Row(
                    children: [
                      _buildReactionEmoji(),
                      const SizedBox(width: 6),
                      Text('$totalReactions', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                if (commentCount > 0)
                  Text('$commentCount comments', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        const Divider(color: AppColors.surfaceDarkElevated, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: _buildActionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: post.isLiked ? 'Liked' : 'Like',
                color: post.isLiked ? AppColors.error : AppColors.textSecondary,
                onTap: onLike,
              )),
              Expanded(child: _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Comment',
                color: AppColors.textSecondary,
                onTap: onComment,
              )),
              Expanded(child: _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: AppColors.textSecondary,
                onTap: onShare,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReactionEmoji() {
    final types = post.reactions.map((r) => r.type).toSet().take(3).toList();
    return Row(
      children: types.map((type) => Text(_reactionEmoji(type), style: const TextStyle(fontSize: 14))).toList(),
    );
  }

  String _reactionEmoji(ReactionType type) {
    switch (type) {
      case ReactionType.like: return '👍';
      case ReactionType.love: return '❤️';
      case ReactionType.fire: return '🔥';
      case ReactionType.clap: return '👏';
      case ReactionType.strong: return '💪';
    }
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
