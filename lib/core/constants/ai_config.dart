class AiConfig {
  static const backendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: 'https://dotcjzbkntwbrizrpzjf.functions.supabase.co/ai',
  );
  static const generatePath = '/resume/generate';
  static const optimizePath = '/resume/optimize';
  static const atsPath = '/resume/ats';
}
