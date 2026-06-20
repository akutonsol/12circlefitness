import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/message_model.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final int index;

  const ConversationTile({super.key, required this.conversation, required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0 ? AppColors.purple.withValues(alpha: 0.05) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: conversation.unreadCount > 0 ? AppColors.purple.withValues(alpha: 0.2) : AppColors.surfaceDarkElevated,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                  child: Text(
                    conversation.participantName[0],
                    style: const TextStyle(color: AppColors.purple, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgDark, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(conversation.participantName,
                          style: TextStyle(color: AppColors.white, fontSize: 15,
                              fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.w600)),
                      Text(_formatTime(conversation.lastMessage?.sentAt ?? conversation.lastActive),
                          style: TextStyle(
                              color: conversation.unreadCount > 0 ? AppColors.purple : AppColors.textTertiary,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDarkElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(conversation.participantRole,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage?.content ?? '',
                          style: TextStyle(
                              color: conversation.unreadCount > 0 ? AppColors.white : AppColors.textSecondary,
                              fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 22, height: 22,
                          decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                          child: Center(
                            child: Text('${conversation.unreadCount}',
                                style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
