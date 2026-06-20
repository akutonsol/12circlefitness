class AppNotification {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id:          j['id'] as String,
    recipientId: j['recipient_id'] as String,
    type:        j['type'] as String? ?? 'general',
    title:       j['title'] as String? ?? '',
    body:        j['body'] as String? ?? '',
    read:        j['read'] as bool? ?? false,
    createdAt:   DateTime.parse(j['created_at'] as String),
    data:        j['data'] as Map<String, dynamic>?,
  );

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id, recipientId: recipientId, type: type, title: title,
    body: body, createdAt: createdAt, data: data,
    read: read ?? this.read,
  );
}
