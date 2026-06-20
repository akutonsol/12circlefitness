enum ClassStatus { upcoming, live, completed, cancelled }
enum ClassCategory { hiit, strength, yoga, cardio, pilates, dance, boxing, meditation }

class ClassInstructor {
  final String id;
  final String name;
  final String role;
  final double rating;

  ClassInstructor({required this.id, required this.name, required this.role, required this.rating});
}

class ClassBooking {
  final String id;
  final String userId;
  final String classId;
  final bool isWaitlisted;
  final DateTime bookedAt;
  final bool attended;
  final String? qrCode;

  ClassBooking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.isWaitlisted,
    required this.bookedAt,
    this.attended = false,
    this.qrCode,
  });
}

class FitnessClass {
  final String id;
  final String title;
  final String description;
  final ClassCategory category;
  final ClassStatus status;
  final DateTime startTime;
  final int durationMinutes;
  final int capacity;
  final int bookedCount;
  final int waitlistCount;
  final ClassInstructor instructor;
  final String location;
  final bool isVirtual;
  final String? streamUrl;
  final bool isBooked;
  final bool isWaitlisted;
  final String? meetingId;
  final List<String> tags;
  final double? price;

  FitnessClass({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.startTime,
    required this.durationMinutes,
    required this.capacity,
    required this.bookedCount,
    required this.waitlistCount,
    required this.instructor,
    required this.location,
    required this.isVirtual,
    this.streamUrl,
    required this.isBooked,
    required this.isWaitlisted,
    this.meetingId,
    required this.tags,
    this.price,
  });

  int get spotsLeft => capacity - bookedCount;
  bool get isFull => bookedCount >= capacity;
  double get fillPercent => (bookedCount / capacity).clamp(0.0, 1.0);
  bool get isLive => status == ClassStatus.live;
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year && startTime.month == now.month && startTime.day == now.day;
  }
}
