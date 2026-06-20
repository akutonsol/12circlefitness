enum MessageType { text, voice, image, video, document }
enum MessageStatus { sending, sent, delivered, read }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime sentAt;
  final String? mediaUrl;
  final int? duration;
  final bool isMe;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.sentAt,
    this.mediaUrl,
    this.duration,
    required this.isMe,
  });
}

class Conversation {
  final String id;
  final String participantId;
  final String participantName;
  final String participantRole;
  final String? participantAvatar;
  final Message? lastMessage;
  final int unreadCount;
  final bool isOnline;
  final DateTime lastActive;

  Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    this.participantAvatar,
    this.lastMessage,
    required this.unreadCount,
    required this.isOnline,
    required this.lastActive,
  });
}
