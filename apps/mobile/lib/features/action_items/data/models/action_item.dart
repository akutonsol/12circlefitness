class ActionItem {
  final String id;
  final String clientId;
  final String? coachId;
  final String title;
  final String description;
  final String category; // daily, weekly, nutrition, workout, accountability, ...
  final String status; // pending | completed
  final int points;
  final String createdBy; // coach | ai | system
  final String? proofUrl;
  final String? clientNotes;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  const ActionItem({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.points,
    required this.createdBy,
    required this.proofUrl,
    required this.clientNotes,
    required this.dueDate,
    required this.completedAt,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  bool get isOverdue =>
      !isCompleted &&
      dueDate != null &&
      dueDate!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

  bool get isDueToday {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  factory ActionItem.fromMap(Map<String, dynamic> m) => ActionItem(
        id: m['id'] as String,
        clientId: m['client_id'] as String,
        coachId: m['coach_id'] as String?,
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        category: m['category'] as String? ?? 'daily',
        status: m['status'] as String? ?? 'pending',
        points: (m['points'] as num?)?.toInt() ?? 10,
        createdBy: m['created_by'] as String? ?? 'coach',
        proofUrl: m['proof_url'] as String?,
        clientNotes: m['client_notes'] as String?,
        dueDate: m['due_date'] != null ? DateTime.tryParse(m['due_date'].toString()) : null,
        completedAt:
            m['completed_at'] != null ? DateTime.tryParse(m['completed_at'].toString()) : null,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  static const categoryEmoji = {
    'onboarding': '🚀',
    'daily': '📋',
    'weekly': '🗓️',
    'nutrition': '🥗',
    'workout': '💪',
    'accountability': '🤝',
    'community': '👥',
    'challenge': '🏆',
  };

  String get emoji => categoryEmoji[category] ?? '📋';
}
