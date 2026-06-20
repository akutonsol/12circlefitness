import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/ai_nutrition_provider.dart';

class AiChatBubble extends StatelessWidget {
  final ChatMessage message;
  const AiChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.2),
                shape: BoxShape.circle),
              child: const Icon(Icons.psychology, color: AppColors.purple, size: 20)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Photo thumbnail (user messages with an image)
                if (isUser && message.image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(message.image!,
                      width: 180, height: 180, fit: BoxFit.cover)),
                  const SizedBox(height: 6),
                ],
                // Text bubble
                if (message.content.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.purple : AppColors.surfaceDark,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16)),
                      border: isUser ? null : Border.all(color: AppColors.surfaceDarkElevated)),
                    child: Text(message.content,
                      style: const TextStyle(
                        color: AppColors.white, fontSize: 14, height: 1.5))),
              ])),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceDarkElevated)),
              child: const Icon(Icons.person_outline, color: AppColors.white, size: 20)),
          ],
        ]));
  }
}
