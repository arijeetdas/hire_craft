class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dotcjzbkntwbrizrpzjf.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvdGNqemJrbnR3YnJpenJwempmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzA1NjIsImV4cCI6MjA4NjkwNjU2Mn0.TmNL2R1C6-j0IbOqbl3KzdesRusKoBsjMZq35YLisd4',
  );
}
