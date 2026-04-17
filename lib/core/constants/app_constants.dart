class AppConstants {
  // App Info
  static const String appName = 'AI Life OS';
  static const String appVersion = '1.0.0';

  // Supabase Tables
  static const String profilesTable = 'profiles';
  static const String tasksTable = 'tasks';
  static const String habitsTable = 'habits';
  static const String moodLogsTable = 'mood_logs';
  static const String mentorMessagesTable = 'mentor_messages';
  static const String personalityScoresTable = 'personality_scores';

  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';

  // OpenRouter — drop-in replacement for OpenAI
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const int maxMentorMemory = 20; // messages to keep in context

  // Mentor System Prompt
  static const String mentorSystemPrompt = '''
You are ARIA — an empathetic, insightful AI life mentor inside the AI Life OS app.

Your personality:
- Warm but direct. You don't sugarcoat, but you're never harsh.
- You remember what the user tells you in this conversation.
- You adapt your tone based on how the user seems to be feeling.
- When they're struggling, you're supportive and gentle.
- When they're doing well, you push them further.

Your expertise:
- Productivity and deep work
- Habit formation and behavioral psychology
- Mental wellness and stress management
- Goal setting and accountability
- Focus and energy management

Rules:
- Keep responses to 2-4 sentences unless the user asks for more.
- Always end with either an action step OR a question — never just a statement.
- Use the user's name when you know it.
- Never be preachy. Give advice once, don't repeat it.
- If you don't know something about the user, ask — don't assume.
''';

  // Personality Traits
  static const List<String> personalityTraits = [
    'discipline',
    'focus',
    'motivation',
    'consistency',
    'energy',
  ];

  // Mood options
  static const List<Map<String, dynamic>> moodOptions = [
    {'label': 'Great', 'emoji': '😄', 'value': 5, 'color': 0xFF1D9E75},
    {'label': 'Good', 'emoji': '🙂', 'value': 4, 'color': 0xFF534AB7},
    {'label': 'Okay', 'emoji': '😐', 'value': 3, 'color': 0xFFBA7517},
    {'label': 'Low', 'emoji': '😔', 'value': 2, 'color': 0xFFD85A30},
    {'label': 'Rough', 'emoji': '😞', 'value': 1, 'color': 0xFFE24B4A},
  ];
}
