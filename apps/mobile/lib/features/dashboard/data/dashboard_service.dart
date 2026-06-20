class DashboardService {

  Future<Map<String, dynamic>> getDashboardData() async {
    return {
      'workout': {
        'title': 'Full Body Strength',
        'duration': 45,
        'calories': 320,
        'completed': false,
        'progress': 0.0,
      },
      'water': {
        'current': 4,
        'goal': 8,
      },
      'steps': {
        'current': 6240,
        'goal': 10000,
      },
      'macros': {
        'calories': {'current': 1240, 'goal': 1800},
        'protein': {'current': 85, 'goal': 120},
        'carbs': {'current': 140, 'goal': 200},
        'fat': {'current': 42, 'goal': 60},
      },
      'streak': {
        'current': 7,
        'longest': 14,
      },
      'quote': {
        'text': 'The body achieves what the mind believes.',
        'author': 'Napoleon Hill',
      },
      'upcoming_class': {
        'title': 'HIIT Cardio Blast',
        'coach': '12 Circle',
        'time': '6:00 PM',
        'date': 'Today',
        'spots': 3,
      },
      'upcoming_event': {
        'title': 'Wellness Workshop',
        'date': 'Jun 15',
        'location': 'Kingston Fitness Hub',
        'registered': false,
      },
    };
  }

  Future<void> updateWaterIntake(int glasses) async {
    // Will persist to Supabase once schema is set up
  }

  Future<void> completeWorkout(String workoutId) async {
    // Will persist to Supabase once schema is set up
  }
}
