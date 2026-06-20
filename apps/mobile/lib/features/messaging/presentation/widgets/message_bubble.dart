import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final int index;

  const MessageBubble({super.key, required this.message, required this.showAvatar, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            showAvatar
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.purple,
                    child: Text(message.senderName[0], style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                : const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isMe ? AppColors.purple : AppColors.surfaceDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isMe ? 18 : 4),
                      bottomRight: Radius.circular(message.isMe ? 4 : 18),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: message.type == MessageType.voice
                      ? _buildVoiceMessage()
                      : Text(message.content, style: const TextStyle(color: AppColors.white, fontSize: 15, height: 1.4)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.sentAt),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    ),
                    if (message.isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 30))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildVoiceMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow, color: AppColors.white, size: 24),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 28, child: CustomPaint(painter: _WaveformPainter())),
              const SizedBox(height: 2),
              Text('${message.duration ?? 0}s', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textTertiary));
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: AppColors.textTertiary);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: AppColors.textTertiary);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: AppColors.purple);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white60..strokeWidth = 2..strokeCap = StrokeCap.round;
    final heights = [0.3, 0.6, 0.8, 0.5, 1.0, 0.7, 0.4, 0.9, 0.6, 0.3, 0.7, 0.5, 0.8, 0.4, 0.6];
    for (int i = 0; i < heights.length; i++) {
      final x = size.width * i / (heights.length - 1);
      final h = size.height * heights[i];
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
