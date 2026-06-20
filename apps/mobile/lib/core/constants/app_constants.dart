
class AppConstants {

  static const String supabaseUrl = 'https://nxdbooufqzkpslkcogxc.supabase.co';

  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54ZGJvb3VmcXprcHNsa2NvZ3hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwMjA4NzksImV4cCI6MjA5NjU5Njg3OX0.D0rl8hxQmDjqknsDCPRuKK1uyIYruSMjycHmNTI-xcE';

  // Pass via: flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
  static const String claudeApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

}

