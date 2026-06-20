import 'models/class_model.dart';

class ClassService {
  final _instructor1 = ClassInstructor(id: 'c1', name: 'Coach Sarah', role: 'Head Coach', rating: 4.9);
  final _instructor2 = ClassInstructor(id: 'c2', name: 'Coach Maya', role: 'Wellness Coach', rating: 4.8);
  final _instructor3 = ClassInstructor(id: 'c3', name: 'Coach Kim', role: 'Nutrition Coach', rating: 4.7);

  List<FitnessClass> getSampleClasses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      FitnessClass(id: '1', title: 'HIIT Cardio Blast', description: 'High intensity interval training to torch calories and build endurance. Bring water and a towel!', category: ClassCategory.hiit, status: ClassStatus.live, startTime: now.subtract(const Duration(minutes: 10)), durationMinutes: 45, capacity: 20, bookedCount: 18, waitlistCount: 3, instructor: _instructor1, location: 'Studio A', isVirtual: false, isBooked: true, isWaitlisted: false, tags: ['Cardio', 'HIIT', 'Fat Burn'], price: null),
      FitnessClass(id: '2', title: 'Full Body Strength', description: 'Build lean muscle and strength with compound movements. All levels welcome.', category: ClassCategory.strength, status: ClassStatus.upcoming, startTime: today.add(const Duration(hours: 18)), durationMinutes: 60, capacity: 15, bookedCount: 9, waitlistCount: 0, instructor: _instructor1, location: 'Weight Room', isVirtual: false, isBooked: false, isWaitlisted: false, tags: ['Strength', 'Muscle', 'Compound'], price: null),
      FitnessClass(id: '3', title: 'Morning Yoga Flow', description: 'Start your day with intention. Gentle yoga flow focusing on flexibility and mindfulness.', category: ClassCategory.yoga, status: ClassStatus.upcoming, startTime: today.add(const Duration(days: 1, hours: 7)), durationMinutes: 50, capacity: 12, bookedCount: 11, waitlistCount: 2, instructor: _instructor2, location: 'Yoga Studio', isVirtual: true, streamUrl: 'https://zoom.us/j/123', isBooked: true, isWaitlisted: false, tags: ['Yoga', 'Flexibility', 'Mindfulness'], price: null),
      FitnessClass(id: '4', title: 'Boxing Fundamentals', description: 'Learn boxing basics while getting an amazing full body workout. Gloves provided.', category: ClassCategory.boxing, status: ClassStatus.upcoming, startTime: today.add(const Duration(days: 1, hours: 17, minutes: 30)), durationMinutes: 60, capacity: 10, bookedCount: 10, waitlistCount: 4, instructor: _instructor1, location: 'Boxing Ring', isVirtual: false, isBooked: false, isWaitlisted: true, tags: ['Boxing', 'Cardio', 'Strength'], price: null),
      FitnessClass(id: '5', title: 'Pilates Core', description: 'Strengthen and tone your core with this challenging pilates session. Mat required.', category: ClassCategory.pilates, status: ClassStatus.upcoming, startTime: today.add(const Duration(days: 2, hours: 9)), durationMinutes: 45, capacity: 15, bookedCount: 7, waitlistCount: 0, instructor: _instructor2, location: 'Studio B', isVirtual: false, isBooked: false, isWaitlisted: false, tags: ['Pilates', 'Core', 'Toning'], price: null),
      FitnessClass(id: '6', title: 'Nutrition Workshop', description: 'Interactive workshop on meal planning, macros and sustainable eating habits with Q&A.', category: ClassCategory.meditation, status: ClassStatus.upcoming, startTime: today.add(const Duration(days: 3, hours: 11)), durationMinutes: 90, capacity: 30, bookedCount: 22, waitlistCount: 0, instructor: _instructor3, location: 'Conference Room', isVirtual: true, streamUrl: 'https://zoom.us/j/456', isBooked: false, isWaitlisted: false, tags: ['Nutrition', 'Education', 'Workshop'], price: null),
      FitnessClass(id: '7', title: 'Dance Cardio', description: 'Fun high energy dance workout. No experience needed — just good vibes!', category: ClassCategory.dance, status: ClassStatus.upcoming, startTime: today.add(const Duration(days: 3, hours: 18)), durationMinutes: 45, capacity: 20, bookedCount: 14, waitlistCount: 0, instructor: _instructor2, location: 'Studio A', isVirtual: false, isBooked: false, isWaitlisted: false, tags: ['Dance', 'Cardio', 'Fun'], price: null),
    ];
  }

  String getCategoryEmoji(ClassCategory category) {
    switch (category) {
      case ClassCategory.hiit: return '⚡';
      case ClassCategory.strength: return '🏋️';
      case ClassCategory.yoga: return '🧘';
      case ClassCategory.cardio: return '🏃';
      case ClassCategory.pilates: return '🤸';
      case ClassCategory.dance: return '💃';
      case ClassCategory.boxing: return '🥊';
      case ClassCategory.meditation: return '🍎';
    }
  }
}
