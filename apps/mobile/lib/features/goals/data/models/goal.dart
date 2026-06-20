class Goal {
  final String id;
  final String clientId;
  final String? coachId;
  final String title;
  final String type; // weight_loss | muscle_gain | body_fat | event_prep | wellness | performance
  final double? startValue;
  final double? currentValue;
  final double? targetValue;
  final String unit;
  final DateTime? targetDate;
  final String status; // active | completed | abandoned
  final DateTime? completedAt;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.title,
    required this.type,
    required this.startValue,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.targetDate,
    required this.status,
    required this.completedAt,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  /// 0.0–1.0 progress toward target. Handles both increasing (muscle gain)
  /// and decreasing (weight/fat loss) goals.
  double get progress {
    if (isCompleted) return 1.0;
    final s = startValue, c = currentValue, t = targetValue;
    if (s == null || c == null || t == null) return 0.0;
    final total = (t - s);
    if (total == 0) return c == t ? 1.0 : 0.0;
    final done = (c - s) / total;
    return done.clamp(0.0, 1.0);
  }

  static const typeLabel = {
    'weight_loss': 'Weight Loss',
    'muscle_gain': 'Muscle Gain',
    'body_fat': 'Body Fat Reduction',
    'event_prep': 'Event Preparation',
    'wellness': 'Wellness Goal',
    'performance': 'Performance',
  };

  static const typeEmoji = {
    'weight_loss': '⚖️',
    'muscle_gain': '💪',
    'body_fat': '🔥',
    'event_prep': '🎯',
    'wellness': '🌿',
    'performance': '🏃',
  };

  String get label => typeLabel[type] ?? 'Goal';
  String get emoji => typeEmoji[type] ?? '🎯';

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as String,
        clientId: m['client_id'] as String,
        coachId: m['coach_id'] as String?,
        title: m['title'] as String? ?? '',
        type: m['type'] as String? ?? 'wellness',
        startValue: (m['start_value'] as num?)?.toDouble(),
        currentValue: (m['current_value'] as num?)?.toDouble(),
        targetValue: (m['target_value'] as num?)?.toDouble(),
        unit: m['unit'] as String? ?? '',
        targetDate: m['target_date'] != null
            ? DateTime.tryParse(m['target_date'].toString())
            : null,
        status: m['status'] as String? ?? 'active',
        completedAt: m['completed_at'] != null
            ? DateTime.tryParse(m['completed_at'].toString())
            : null,
        createdAt:
            DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
